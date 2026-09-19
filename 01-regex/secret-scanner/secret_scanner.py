#!/usr/bin/env python3
"""
Automated Secret & API Key Leak Scanner
=======================================
A standalone Python script using standard library 're' to scan code and
configuration files for leaked API keys, tokens, and passwords.
"""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

# ==============================================================================
# REGEX RULES
# We compile regular expressions here for fast performance.
# Each pattern uses lookarounds, non-capturing groups, and boundary anchors
# to avoid false positives and eliminate Catastrophic Backtracking (ReDoS).
# ==============================================================================

RULES = {
    # 1. AWS Access Key ID:
    # Matches standard 20-character AWS keys that start with 'AKIA'.
    # - (?<![A-Z0-9]) : Negative lookbehind. Ensures there is no letter or number right
    #                   before 'AKIA', so we don't match inside a longer random hash.
    # - (AKIA[0-9A-Z]{16}) : Matches literal 'AKIA' followed by exactly 16 uppercase letters/digits.
    # - (?![0-9A-Z])  : Negative lookahead. Ensures there is no letter or number right after,
    #                   so we only match if the key is exactly 20 characters long.
    "AWS Access Key ID": re.compile(
        r"(?<![A-Z0-9])(AKIA[0-9A-Z]{16})(?![0-9A-Z])"
    ),

    # 2. AWS Secret Access Key:
    # Matches 40-character base64 keys assigned to AWS variable names.
    # - (?i) : Case-insensitive flag so it matches both upper and lower case variable names.
    # - ['"]?\b(?:aws_secret_access_key|aws_secret_key|aws_secret|secret_access_key)\b['"]? :
    #   Word boundary \b and non-capturing group (?:...) match common AWS key variable names.
    # - \s*[:=]\s* : Matches '=' or ':' assignment with optional spaces.
    # - ['"]?([A-Za-z0-9/+=]{40})['"]? : Captures exactly 40 base64 characters. Fixed length prevents ReDoS.
    # - (?=[;\s,\r\n'"]|$) : Positive lookahead. Confirms line end or delimiter without consuming it.
    "AWS Secret Access Key": re.compile(
        r"(?i)['\"]?\b(?:aws_secret_access_key|aws_secret_key|aws_secret|secret_access_key)\b['\"]?\s*[:=]\s*['\"]?([A-Za-z0-9/+=]{40})['\"]?(?=[;\s,\r\n'\"]|$)"
    ),

    # 3. GitHub Personal Access Token (Classic):
    # Matches classic GitHub tokens that begin with 'ghp_'.
    # - (?<![a-zA-Z0-9]) : Negative lookbehind. Prevents matching inside a longer word or hash.
    # - (ghp_[0-9a-zA-Z]{36}) : Matches 'ghp_' followed by exactly 36 alphanumeric characters.
    # - (?![a-zA-Z0-9])  : Negative lookahead. Confirms the token ends cleanly at 40 characters total.
    "GitHub Personal Access Token (Classic)": re.compile(
        r"(?<![a-zA-Z0-9])(ghp_[0-9a-zA-Z]{36})(?![a-zA-Z0-9])"
    ),

    # 4. GitHub Fine-Grained Personal Access Token:
    # Matches scoped GitHub tokens that begin with 'github_pat_'.
    # - (?<![a-zA-Z0-9]) : Negative lookbehind boundary.
    # - (github_pat_[0-9a-zA-Z_]{82,100}) : Matches 'github_pat_' followed by 82 to 100 valid token characters.
    # - (?![a-zA-Z0-9_]) : Negative lookahead boundary. Bounded range prevents ReDoS backtracking.
    "GitHub Fine-Grained Personal Access Token": re.compile(
        r"(?<![a-zA-Z0-9])(github_pat_[0-9a-zA-Z_]{82,100})(?![a-zA-Z0-9_])"
    ),

    # 5. Stripe API Keys (Live / Test):
    # Matches Stripe secret, public, and restricted keys.
    # - (?<![a-zA-Z0-9]) : Negative lookbehind boundary.
    # - (?:sk|pk|rk) : Non-capturing group for Secret (sk), Publishable (pk), or Restricted (rk) key.
    # - _(?:live|test)_ : Non-capturing group for live or test environment mode.
    # - [0-9a-zA-Z]{24,99} : Bounded range of 24 to 99 characters prevents catastrophic backtracking.
    # - (?![a-zA-Z0-9]) : Negative lookahead boundary.
    "Stripe API Key": re.compile(
        r"(?<![a-zA-Z0-9])((?:sk|pk|rk)_(?:live|test)_[0-9a-zA-Z]{24,99})(?![a-zA-Z0-9])"
    ),

    # 6. Slack Token (Bot / User):
    # Matches Slack tokens used by bots and apps.
    # - (?<![a-zA-Z0-9]) : Negative lookbehind boundary.
    # - xox[baprs] : Matches Slack token prefix family (like bot 'xoxb', app 'xoxa', etc.).
    # - -(?:[0-9]{11,13}|[0-9]{10,13})-[0-9]{11,13} : Matches numerical workspace and user IDs.
    # - -[a-zA-Z0-9]{24,34} : Matches the token secret string.
    # - (?![a-zA-Z0-9]) : Negative lookahead boundary.
    "Slack Token": re.compile(
        r"(?<![a-zA-Z0-9])(xox[baprs]-(?:[0-9]{11,13}|[0-9]{10,13})-[0-9]{11,13}-[a-zA-Z0-9]{24,34})(?![a-zA-Z0-9])"
    ),

    # 7. Generic Password / Secret Assignment:
    # Matches credentials assigned in code or config files (.env, .json, .yaml, .py, .js).
    # - (?i) : Case-insensitive matching.
    # - ['"]?\b(?:password|passwd|pwd|secret|api_key|apikey|auth_token|access_token|client_secret)\b['"]? :
    #   Word boundary \b and non-capturing group match common secret keys (bare or in quotes for JSON).
    # - \s*[:=]\s* : Matches assignment operator '=' or ':'.
    # - ['"] : Opening quote literal.
    # - (?!(?:password123|TODO|CHANGEME|CHANGE_ME|dummy|admin|test|example|placeholder|null)(?:['"]|$)) :
    #   Negative lookahead. Rejects trivial dummy defaults like 'password123' or 'TODO'.
    # - ([^'"\s]{8,128}) : Captures the secret string (8 to 128 characters without spaces or quotes).
    # - ['"] : Closing quote literal.
    # - (?=[;\s,\r\n]|$) : Positive lookahead ensuring delimiter or end of line.
    "Generic Credential Assignment": re.compile(
        r"(?i)['\"]?\b(?:password|passwd|pwd|secret|api_key|apikey|auth_token|access_token|client_secret)\b['\"]?\s*[:=]\s*['\"](?!(?:password123|TODO|CHANGEME|CHANGE_ME|dummy|admin|test|example|placeholder|null)(?:['\"]|$))([^'\"\s]{8,128})['\"](?=[;\s,\r\n]|$)"
    ),
}

# Folders and file extensions to ignore during recursive search
IGNORED_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", "dist", "build"}
IGNORED_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".zip", ".tar", ".gz", ".exe", ".pdf", ".pyc", ".lock"}


def mask_secret(secret: str) -> str:
    """
    Masks a secret to hide sensitive data in reports and logs.
    Shows the first 4 and last 4 characters, replacing the middle with asterisks (*).
    Example: 'AKIAIOSFODNN7EXAMPLE' -> 'AKIA************MPLE'
    """
    if len(secret) <= 8:
        return "*" * len(secret)
    return secret[:4] + ("*" * (len(secret) - 8)) + secret[-4:]


def find_files(target: Path):
    """
    Finds all files to scan under the target path.
    Skips noisy dependency folders (like node_modules and .git) and binary files.
    """
    if target.is_file():
        yield target
        return
    for root, dirs, files in os.walk(target):
        # Prune ignored folders so we don't waste time scanning them
        dirs[:] = [d for d in dirs if d not in IGNORED_DIRS and not d.startswith(".git")]
        for f in files:
            p = Path(root) / f
            if p.suffix.lower() not in IGNORED_EXTS:
                yield p


def scan_file(file_path: Path, base_dir: Path):
    """
    Reads a file line-by-line and tests each line against all regex rules.
    Gracefully handles encoding errors by replacing unreadable characters.
    """
    findings = []
    try:
        rel_path = str(file_path.relative_to(base_dir))
    except ValueError:
        rel_path = str(file_path)
    abs_path = str(file_path.resolve())

    try:
        # Use errors='replace' to avoid crashing on non-UTF-8 characters
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            for line_no, line in enumerate(f, start=1):
                for rule_name, pattern in RULES.items():
                    for match in pattern.finditer(line):
                        # Extract the captured secret string
                        raw = match.group(1) if match.groups() else match.group(0)
                        masked = mask_secret(raw)
                        # Replace raw secret with masked version in the code snippet
                        snippet = line.replace(raw, masked).strip("\r\n")
                        findings.append({
                            "rule": rule_name,
                            "rel_path": rel_path,
                            "abs_path": abs_path,
                            "line": line_no,
                            "masked": masked,
                            "snippet": snippet[:150]
                        })
    except (OSError, PermissionError):
        # Skip files that cannot be opened due to OS permissions
        pass
    return findings


def write_report(findings, target_path, files_count, duration, out_path, is_json):
    """
    Saves scan results to an output file in text or JSON format.
    Details: Secret Type, Relative Path, Absolute Path, Line Number, Masked Secret, and Code Snippet.
    """
    out = Path(out_path).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)

    if is_json:
        data = {
            "summary": {
                "target": str(target_path),
                "files_scanned": files_count,
                "leaks_found": len(findings),
                "duration_seconds": round(duration, 4)
            },
            "findings": findings
        }
        out.write_text(json.dumps(data, indent=2), encoding="utf-8")
    else:
        lines = [
            "=" * 70,
            "SECRET SCAN AUDIT REPORT",
            "=" * 70,
            f"Target: {target_path} | Files Scanned: {files_count} | Leaks Found: {len(findings)} | Time: {duration:.4f}s",
            "=" * 70,
            ""
        ]
        for i, f in enumerate(findings, 1):
            lines.extend([
                f"[{i}] {f['rule']}",
                f"  Relative Path : {f['rel_path']}",
                f"  Absolute Path : {f['abs_path']}",
                f"  Line Number   : {f['line']}",
                f"  Masked Secret : {f['masked']}",
                f"  Sanitized Line: {f['snippet']}",
                "-" * 70
            ])
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return out


def run_test():
    """
    Built-in self-test to verify detection and masking on synthetic sample strings.
    """
    samples = [
        ('AWS_KEY = "AKIAIOSFODNN7EXAMPLE"', "AWS Access Key ID"),
        ('aws_secret = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"', "AWS Secret Access Key"),
        ('ghp = "ghp_16C7e42F292c6912E7710c838347Ae178B4a"', "GitHub Personal Access Token (Classic)"),
        ('stripe = "sk_test_51M0abcdefghijklmnopqrstuvwxyz1234567890ABC"', "Stripe API Key"),
        ('slack = "xoxs-123456789012-123456789012-abcdefghijklmnopqrstuvwx"', "Slack Token"),
    ]
    for text, rule in samples:
        match = RULES[rule].search(text)
        assert match is not None, f"Failed match for {rule}"
    assert mask_secret("AKIAIOSFODNN7EXAMPLE") == "AKIA************MPLE"
    print("[PASS] Built-in regex and masking tests passed.")
    return 0


def main():
    """
    CLI entry point. Parses arguments, runs scan, prints summary, and writes report.
    """
    parser = argparse.ArgumentParser(description="Automated Secret & API Key Leak Scanner")
    parser.add_argument("path", nargs="?", default=".", help="Target path to scan")
    parser.add_argument("--target", "-t", default=None, help="Target path")
    parser.add_argument("--output", "-o", default="secret_scan_report.txt", help="Report path")
    parser.add_argument("--format", "-f", choices=["txt", "json"], default="txt", help="Report format")
    parser.add_argument("--json", action="store_true", help="Output report as JSON")
    parser.add_argument("--test", action="store_true", help="Run test checks")
    args = parser.parse_args()

    # Run self-test if --test flag was passed
    if args.test:
        return run_test()

    # Resolve target directory or file path
    target = Path(args.target or args.path).resolve()
    if not target.exists():
        print(f"Error: Target path '{target}' does not exist.")
        return 2

    base_dir = target if target.is_dir() else target.parent
    start = time.perf_counter()
    findings = []
    files_count = 0

    # Scan all discovered files
    for file_path in find_files(target):
        files_count += 1
        findings.extend(scan_file(file_path, base_dir))

    duration = time.perf_counter() - start
    report_file = None

    # Automatically write report if leaks were found
    if findings:
        is_json = args.json or (args.format == "json")
        report_file = write_report(findings, target, files_count, duration, args.output, is_json)

    # Print summary banner to terminal
    print("\n" + "=" * 60)
    print("           SECRET SCAN SUMMARY")
    print("=" * 60)
    print(f"Target       : {target}")
    print(f"Duration     : {duration:.4f}s")
    print(f"Files Scanned: {files_count}")
    print(f"Leaks Found  : {len(findings)}")
    print(f"Report File  : {report_file if report_file else 'None (Clean)'}")
    print(f"Status       : {'FAILED - LEAKS DETECTED' if findings else 'PASSED - CLEAN'}")
    print("=" * 60 + "\n")

    # Exit code: 1 if secrets found, 0 if clean
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
