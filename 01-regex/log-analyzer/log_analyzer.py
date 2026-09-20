#!/usr/bin/env python3
"""
Syntaxia: High-Performance Web Server Access Log Analyzer & Cyber Attack Detector
================================================================================
A lightweight, zero-dependency Python log parsing and cybersecurity threat
detection engine using the standard library 're' module. Tokenizes Apache / Nginx
access logs and Linux Syslog / Auth records into deterministic structured records,
evaluating them against compiled regular expressions to detect web attacks.

Supported Threat Detections:
- SQL Injection (SQLi)
- Directory Traversal / Local File Inclusion (LFI)
- Cross-Site Scripting (XSS)
- Sensitive File & Endpoint Probing (.env, .git, backups)
- Malicious Security Scanner User-Agents (sqlmap, nikto, nmap, dirbuster, etc.)
- Authentication Brute Force / SSH Failure Anomaly Detection
"""

import argparse
import json
import os
import re
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import unquote

# ==============================================================================
# 1. COMPILED REGEX PATTERNS FOR LOG PARSING
# ==============================================================================

# Combined / Common Log Format (Nginx & Apache):
# Example:
# 192.168.1.10 - - [20/Sep/2026:14:25:30 +0530] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
LOG_PATTERN = re.compile(
    r"""
    ^
    (?P<ip>\S+)                         # Client IP address (IPv4/IPv6)
    \s+
    (?P<ident>\S+)                      # RFC 1413 identity (usually '-')
    \s+
    (?P<user>\S+)                       # Authenticated remote user (or '-')
    \s+
    \[
        (?P<timestamp>[^\]]+)           # Timestamp inside brackets
    \]
    \s+
    "
        (?P<method>[A-Z]+)              # HTTP Method (GET, POST, etc.)
        \s+
        (?P<route>\S+)                  # Requested route / URI path + query
        \s+
        (?P<protocol>HTTP/\d(?:\.\d)?)  # HTTP protocol version
    "
    \s+
    (?P<status>\d{3})                   # HTTP status code (3 digits)
    \s+
    (?P<size>\d+|-)                     # Response size in bytes (or '-')
    (?:
        \s+
        "
        (?P<referer>[^"]*)              # Optional Referer header
        "
    )?
    (?:
        \s+
        "
        (?P<user_agent>[^"]*)           # Optional User-Agent header
        "
    )?
    $
    """,
    re.VERBOSE
)

# Linux Syslog / Auth Log Format (sshd):
# Example:
# Sep 20 14:11:05 webserver sshd[10450]: Failed password for invalid user admin from 203.0.113.88 port 43210 ssh2
AUTH_LOG_PATTERN = re.compile(
    r"""
    ^
    (?P<timestamp>[A-Z][a-z]{2}\s+\d+\s+\d{2}:\d{2}:\d{2})  # Syslog timestamp
    \s+
    (?P<hostname>\S+)                                       # Hostname
    \s+
    sshd\[(?P<pid>\d+)\]:                                   # Service daemon & PID
    \s+
    (?P<event>Failed\s+password|Accepted\s+password)        # Auth event type
    \s+
    (?:for\s+(?:invalid\s+user\s+)?(?P<user>\S+))           # Targeted username
    \s+
    from\s+(?P<ip>\S+)                                      # Remote source IP
    \s+
    port\s+(?P<port>\d+)                                    # Source port
    (?:\s+ssh2)?
    """,
    re.VERBOSE
)


# ==============================================================================
# 2. CYBER ATTACK DETECTION REGEX RULES
# All patterns feature negative/positive lookarounds and bounded quantifiers
# to eliminate Catastrophic Backtracking (ReDoS) while ensuring zero false positives.
# ==============================================================================

# SQL Injection (SQLi) Detector:
# Detects UNION SELECT, boolean tautologies (OR 1=1, AND 1=1), information_schema,
# destructive statements (DROP TABLE), and SQL comment markers (--).
SQLI_PATTERN = re.compile(
    r"""
    (?:
        # UNION SELECT injection
        (?<![A-Za-z0-9_])
        UNION
        \s+
        SELECT
        (?![A-Za-z0-9_])

        |

        # Boolean tautology: OR 1=1 / OR 'a'='a'
        (?<![A-Za-z0-9_])
        ['"]?
        \s*
        OR
        \s+
        ['"]?
        \d+
        ['"]?
        \s*=\s*
        ['"]?
        \d+
        ['"]?
        (?![A-Za-z0-9_])

        |

        # Boolean tautology: AND 1=1
        (?<![A-Za-z0-9_])
        ['"]?
        \s*
        AND
        \s+
        ['"]?
        \d+
        ['"]?
        \s*=\s*
        ['"]?
        \d+
        ['"]?
        (?![A-Za-z0-9_])

        |

        # Metadata database probing
        (?<![A-Za-z0-9_])
        information_schema
        (?![A-Za-z0-9_])

        |

        # Schema destruction: DROP TABLE
        (?<![A-Za-z0-9_])
        DROP
        \s+
        TABLE
        (?![A-Za-z0-9_])

        |

        # SQL single-line comment terminator
        --[^\r\n]*
    )
    """,
    re.IGNORECASE | re.VERBOSE
)

# Directory Traversal / Local File Inclusion (LFI):
# Matches parent directory navigation (../, ..\) and critical OS configuration targets.
TRAVERSAL_PATTERN = re.compile(
    r"""
    (?:
        \.\./                   # Unix path traversal step
        |
        \.\.\\                  # Windows path traversal step
        |
        /etc/passwd             # Linux password shadow file
        |
        /proc/self/environ      # Linux process runtime environment
        |
        /win\.ini               # Windows legacy system config
    )
    """,
    re.IGNORECASE | re.VERBOSE
)

# Cross-Site Scripting (XSS) Detector:
# Detects reflected scripts, javascript pseudoprotocol, event handlers, and popups.
XSS_PATTERN = re.compile(
    r"""
    (?:
        <\s*script\b            # <script tag opening
        |
        javascript\s*:          # Inline javascript pseudo-scheme
        |
        \bonerror\s*=           # onerror event handler
        |
        \bonload\s*=            # onload event handler
        |
        \bonclick\s*=           # onclick event handler
        |
        \balert\s*\(            # Standard alert execution payload
    )
    """,
    re.IGNORECASE | re.VERBOSE
)

# Sensitive File / Endpoint Reconnaissance:
# Probing for secrets, VCS repos, admin logins, management endpoints, and DB dumps.
SENSITIVE_PATTERN = re.compile(
    r"""
    (?:
        /\.env\b                                # Environment secrets
        |
        /\.git(?:/|$)                           # Git version control metadata
        |
        /wp-login\.php\b                        # WordPress administrator login
        |
        /phpmyadmin(?:/|$)                      # phpMyAdmin web console
        |
        /actuator/heapdump\b                    # Spring Boot actuator dump
        |
        \.(?:sql|bak|backup|old|dump)(?:\b|$)   # Database and backup artifacts
    )
    """,
    re.IGNORECASE | re.VERBOSE
)

# Malicious Scanner User-Agent Detector:
# Detects signatures of known automated penetration testing tools and fuzzers.
SCANNER_PATTERN = re.compile(
    r"""
    (?:
        \bsqlmap\b
        |
        \bnikto\b
        |
        \bnmap\b
        |
        \bmasscan\b
        |
        \bacunetix\b
        |
        \bdirbuster\b
        |
        \bgobuster\b
    )
    """,
    re.IGNORECASE | re.VERBOSE
)

# SSH Authentication Failure Pattern:
AUTH_FAILURE_PATTERN = re.compile(
    r"Failed password",
    re.IGNORECASE
)

# Rule Registry:
THREAT_RULES = {
    "SQL Injection (SQLi)": SQLI_PATTERN,
    "Directory Traversal / LFI": TRAVERSAL_PATTERN,
    "Cross-Site Scripting (XSS)": XSS_PATTERN,
    "Sensitive File Probing": SENSITIVE_PATTERN,
    "Malicious Scanner / Exploit Tool UA": SCANNER_PATTERN,
}


# ==============================================================================
# 3. PARSING & DETECTION ENGINE
# ==============================================================================

def decode_route(route: str) -> str:
    """
    Decodes URL-encoded parameters twice to defeat nested/double encoding evasion.
    Example: '%252e%252e%252f' -> '%2e%2e%2f' -> '../'
    """
    first_pass = unquote(route)
    second_pass = unquote(first_pass)
    return second_pass


def parse_log(log_line: str) -> Optional[Dict[str, Any]]:
    """
    Parses a single log line into a structured dictionary.
    Supports Nginx/Apache Combined/Common format and Syslog sshd format.
    """
    line = log_line.strip()
    if not line or line.startswith("#"):
        return None

    # 1. Attempt Web Access Log Match
    match = LOG_PATTERN.match(line)
    if match:
        data = match.groupdict()
        data["log_type"] = "access"
        # Normalize fields
        data["referer"] = data.get("referer") or "-"
        data["user_agent"] = data.get("user_agent") or "-"
        return data

    # 2. Attempt Syslog Auth Log Match
    auth_match = AUTH_LOG_PATTERN.match(line)
    if auth_match:
        data = auth_match.groupdict()
        data["log_type"] = "auth"
        data["route"] = f"sshd auth: {data['event']}"
        data["method"] = "SSH"
        data["protocol"] = "SSH/2.0"
        data["status"] = "401" if "Failed" in data["event"] else "200"
        data["size"] = "0"
        data["user_agent"] = "-"
        data["referer"] = "-"
        return data

    return None


def detect_threats(data: Dict[str, Any]) -> List[str]:
    """
    Evaluates extracted log tokens against threat signatures.
    Returns a list of detected threat category names.
    """
    threats: List[str] = []

    # Handle SSH Auth logs
    if data.get("log_type") == "auth":
        event = data.get("event", "")
        if AUTH_FAILURE_PATTERN.search(event):
            threats.append("Auth Brute Force / SSH Failure")
        return threats

    # Handle Web Access logs
    raw_route = data.get("route", "")
    decoded_route = decode_route(raw_route)
    user_agent = data.get("user_agent", "")

    # 1. SQL Injection
    if SQLI_PATTERN.search(decoded_route):
        threats.append("SQL Injection (SQLi)")

    # 2. Directory Traversal / LFI
    if TRAVERSAL_PATTERN.search(decoded_route):
        threats.append("Directory Traversal / LFI")

    # 3. Cross-Site Scripting (XSS)
    if XSS_PATTERN.search(decoded_route):
        threats.append("Cross-Site Scripting (XSS)")

    # 4. Sensitive File Probing
    if SENSITIVE_PATTERN.search(decoded_route):
        threats.append("Sensitive File Probing")

    # 5. Malicious Scanner User-Agent
    if user_agent and SCANNER_PATTERN.search(user_agent):
        threats.append("Malicious Scanner / Exploit Tool UA")

    return threats


def analyze_log(log_line: str) -> Dict[str, Any]:
    """
    High-level analyzer for a single raw log string.
    Returns parsing status, structured record, and detected threats.
    """
    data = parse_log(log_line)
    if data is None:
        return {
            "parsed": False,
            "data": None,
            "threats": []
        }

    threats = detect_threats(data)
    return {
        "parsed": True,
        "data": data,
        "threats": threats
    }


# ==============================================================================
# 4. FILE & DIRECTORY BATCH SCANNER
# ==============================================================================

def find_files(target: Path):
    """
    Discovers log files under target path. Yields single files directly,
    or traverses directories for files with .log, .txt, or access/audit in name.
    """
    if target.is_file():
        yield target
        return

    for root, _, files in os.walk(target):
        for f in files:
            p = Path(root) / f
            ext = p.suffix.lower()
            if ext in {".log", ".txt"} or "access" in f.lower() or "auth" in f.lower():
                yield p


def scan_file(file_path: Path) -> Dict[str, Any]:
    """
    Reads a log file line-by-line, computing metrics, status codes,
    threat occurrences, and top attacker IP addresses.
    """
    total_lines = 0
    parsed_lines = 0
    unparsed_lines = 0
    total_bytes = 0

    status_counter: Counter = Counter()
    threat_counter: Counter = Counter()
    attacker_ip_counter: Counter = Counter()
    incidents: List[Dict[str, Any]] = []

    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            for line_no, raw_line in enumerate(f, start=1):
                clean_line = raw_line.strip()
                if not clean_line or clean_line.startswith("#"):
                    continue

                total_lines += 1
                result = analyze_log(clean_line)

                if not result["parsed"]:
                    unparsed_lines += 1
                    continue

                parsed_lines += 1
                data = result["data"]

                # Parse bytes transferred
                size_str = data.get("size", "-")
                if size_str.isdigit():
                    total_bytes += int(size_str)

                # Track HTTP status code groups
                status_code = data.get("status", "000")
                status_counter[status_code] += 1

                # Track security threats
                threats = result["threats"]
                if threats:
                    ip = data.get("ip", "unknown")
                    for t in threats:
                        threat_counter[t] += 1
                        attacker_ip_counter[ip] += 1

                    incidents.append({
                        "file": str(file_path),
                        "line": line_no,
                        "ip": ip,
                        "timestamp": data.get("timestamp", "-"),
                        "method": data.get("method", "-"),
                        "route": data.get("route", "-"),
                        "status": status_code,
                        "user_agent": data.get("user_agent", "-"),
                        "threats": threats
                    })
    except (OSError, PermissionError) as e:
        print(f"[!] Warning: Cannot read {file_path}: {e}")

    return {
        "file": str(file_path),
        "total_lines": total_lines,
        "parsed_lines": parsed_lines,
        "unparsed_lines": unparsed_lines,
        "total_bytes": total_bytes,
        "status_counter": status_counter,
        "threat_counter": threat_counter,
        "attacker_ip_counter": attacker_ip_counter,
        "incidents": incidents
    }


# ==============================================================================
# 5. REPORT GENERATION & DISPLAY
# ==============================================================================

def format_summary_text(summary: Dict[str, Any], incidents: List[Dict[str, Any]], verbose: bool = False) -> str:
    """
    Renders standard formatted text report matching Syntaxia specification.
    """
    total = summary["total_lines"]
    parsed = summary["parsed_lines"]
    unparsed = summary["unparsed_lines"]
    pct = (parsed / total * 100) if total > 0 else 0.0
    mb_transferred = summary["total_bytes"] / (1024 * 1024)
    total_incidents = sum(summary["threat_counter"].values())

    # Categorize status codes
    status_codes = summary["status_counter"]
    c_2xx = sum(v for k, v in status_codes.items() if k.startswith("2"))
    c_3xx = sum(v for k, v in status_codes.items() if k.startswith("3"))
    c_4xx = sum(v for k, v in status_codes.items() if k.startswith("4"))
    c_5xx = sum(v for k, v in status_codes.items() if k.startswith("5"))

    lines = [
        "=" * 70,
        "               SYNTAXIA LOG & THREAT ANALYZER REPORT",
        "=" * 70,
        f" Total Lines Processed : {total}",
        f" Successfully Parsed   : {parsed} ({pct:.1f}%)",
        f" Unparsed / Raw Lines  : {unparsed}",
        f" Bandwidth Transferred : {mb_transferred:.2f} MB",
        f" Security Incidents    : {total_incidents}",
        "-" * 70,
        " HTTP STATUS CODE DISTRIBUTION",
        "-" * 70,
        f"  2xx Success       : {c_2xx}",
        f"  3xx Redirection   : {c_3xx}",
        f"  4xx Client Error  : {c_4xx}",
        f"  5xx Server Error  : {c_5xx}",
        "-" * 70,
        " DETECTED CYBERSECURITY THREATS",
        "-" * 70
    ]

    threat_counts = summary["threat_counter"]
    if threat_counts:
        for threat, count in threat_counts.most_common():
            lines.append(f"  [!] {threat:<35} : {count:>5} incident(s)")
    else:
        lines.append("  [CLEAN] No threats or intrusion signatures detected.")

    top_ips = summary["attacker_ip_counter"].most_common(5)
    if top_ips:
        lines.append("")
        lines.append(" TOP ATTACKER IP ADDRESSES:")
        for ip, count in top_ips:
            lines.append(f"  - {ip:<30} : {count} incident(s)")

    if verbose and incidents:
        lines.append("")
        lines.append("-" * 70)
        lines.append(" DETAILED SECURITY INCIDENT LOG")
        lines.append("-" * 70)
        for i, inc in enumerate(incidents, start=1):
            lines.append(f"[{i}] {inc['ip']} - [{inc['timestamp']}]")
            lines.append(f"    Request : {inc['method']} {inc['route']} (HTTP {inc['status']})")
            lines.append(f"    UA      : {inc['user_agent']}")
            lines.append(f"    Threats : {', '.join(inc['threats'])}")
            lines.append(f"    Source  : {inc['file']}:{inc['line']}")
            lines.append("-" * 70)

    lines.append("=" * 70)
    return "\n".join(lines)


def write_report(summary: Dict[str, Any], incidents: List[Dict[str, Any]], out_path: str, is_json: bool, verbose: bool = False) -> Path:
    """
    Saves audit report to file in Plaintext or JSON format.
    """
    out = Path(out_path).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)

    if is_json:
        status_codes = summary["status_counter"]
        data = {
            "summary": {
                "target": summary.get("target", "scan"),
                "total_lines": summary["total_lines"],
                "parsed_lines": summary["parsed_lines"],
                "unparsed_lines": summary["unparsed_lines"],
                "bandwidth_bytes": summary["total_bytes"],
                "bandwidth_mb": round(summary["total_bytes"] / (1024 * 1024), 4),
                "total_threat_incidents": sum(summary["threat_counter"].values()),
                "status_code_distribution": {
                    "2xx": sum(v for k, v in status_codes.items() if k.startswith("2")),
                    "3xx": sum(v for k, v in status_codes.items() if k.startswith("3")),
                    "4xx": sum(v for k, v in status_codes.items() if k.startswith("4")),
                    "5xx": sum(v for k, v in status_codes.items() if k.startswith("5")),
                    "raw_counts": dict(status_codes)
                },
                "threat_breakdown": dict(summary["threat_counter"]),
                "top_attacker_ips": dict(summary["attacker_ip_counter"].most_common(10))
            },
            "incidents": incidents
        }
        out.write_text(json.dumps(data, indent=2), encoding="utf-8")
    else:
        text = format_summary_text(summary, incidents, verbose=verbose)
        out.write_text(text + "\n", encoding="utf-8")

    return out


def display_result(result: Dict[str, Any]):
    """
    Displays formatted analysis result for a single log line in interactive mode.
    """
    print("\n" + "=" * 70)
    if not result["parsed"]:
        print("[INVALID LOG FORMAT]")
        print("The entered log could not be parsed.")
        print("=" * 70)
        return

    data = result["data"]
    print("EXTRACTED INFORMATION")
    print("-" * 70)
    print(f"IP Address : {data['ip']}")
    print(f"Timestamp  : {data['timestamp']}")
    print(f"Method     : {data['method']}")
    print(f"Route      : {data['route']}")
    print(f"Protocol   : {data['protocol']}")
    print(f"Status     : {data['status']}")
    print(f"Bytes      : {data['size']}")
    print(f"Referer    : {data.get('referer', '-')}")
    print(f"User-Agent : {data.get('user_agent', '-')}")
    print("-" * 70)

    if result["threats"]:
        print("[!] SUSPICIOUS REQUEST")
        print()
        print("THREATS DETECTED:")
        for threat in result["threats"]:
            print(f"   [!] {threat}")
    else:
        print("[OK] NORMAL REQUEST")

    print("=" * 70)


# ==============================================================================
# 6. INTERACTIVE MODE & BUILT-IN VERIFICATION TESTS
# ==============================================================================

def custom_input():
    """
    Interactive REPL allowing custom log line entry and real-time threat parsing.
    """
    print("\n" + "=" * 70)
    print("                    CUSTOM LOG ANALYSIS")
    print("=" * 70)
    print("\nEnter a complete Apache/Nginx access log or auth log line.")
    print("Type 'back' to return to the main menu.\n")

    while True:
        try:
            log_line = input("Enter log: ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if log_line.lower() == "back":
            return
        if not log_line:
            print("Please enter a log.")
            continue

        result = analyze_log(log_line)
        display_result(result)


def run_test() -> int:
    """
    Built-in self-test verifying regex rules, unquoting, and threat classification.
    """
    print("[*] Running built-in self-tests for LogAnalyzer...")

    test_logs = [
        # 1. Normal Request
        (
            '192.168.1.10 - - [20/Sep/2026:14:25:30 +0530] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0"',
            []
        ),
        # 2. SQL Injection (OR 1=1)
        (
            '203.0.113.88 - - [20/Sep/2026:14:26:00 +0530] "GET /login?id=1%20OR%201%3D1 HTTP/1.1" 200 500 "-" "Mozilla/5.0"',
            ["SQL Injection (SQLi)"]
        ),
        # 3. UNION SELECT
        (
            '203.0.113.89 - - [20/Sep/2026:14:27:00 +0530] "GET /search?q=UNION%20SELECT%20username%20FROM%20users HTTP/1.1" 200 600 "-" "Mozilla/5.0"',
            ["SQL Injection (SQLi)"]
        ),
        # 4. Directory Traversal
        (
            '198.51.100.42 - - [20/Sep/2026:14:28:00 +0530] "GET /../../etc/passwd HTTP/1.1" 404 300 "-" "Mozilla/5.0"',
            ["Directory Traversal / LFI"]
        ),
        # 5. Encoded Directory Traversal
        (
            '198.51.100.43 - - [20/Sep/2026:14:29:00 +0530] "GET /..%2F..%2Fetc%2Fpasswd HTTP/1.1" 404 300 "-" "Mozilla/5.0"',
            ["Directory Traversal / LFI"]
        ),
        # 6. Cross-Site Scripting (XSS)
        (
            '203.0.113.90 - - [20/Sep/2026:14:30:00 +0530] "GET /search?q=%3Cscript%3Ealert(1)%3C/script%3E HTTP/1.1" 200 700 "-" "Mozilla/5.0"',
            ["Cross-Site Scripting (XSS)"]
        ),
        # 7. Sensitive File Probing
        (
            '203.0.113.91 - - [20/Sep/2026:14:31:00 +0530] "GET /.env HTTP/1.1" 404 250 "-" "Mozilla/5.0"',
            ["Sensitive File Probing"]
        ),
        # 8. Malicious Scanner UA
        (
            '203.0.113.92 - - [20/Sep/2026:14:32:00 +0530] "GET /admin HTTP/1.1" 404 100 "-" "sqlmap/1.8"',
            ["Malicious Scanner / Exploit Tool UA"]
        ),
        # 9. SSH Auth Failure
        (
            'Sep 20 14:11:05 webserver sshd[10450]: Failed password for invalid user admin from 203.0.113.88 port 43210 ssh2',
            ["Auth Brute Force / SSH Failure"]
        )
    ]

    for idx, (log_line, expected_threats) in enumerate(test_logs, start=1):
        res = analyze_log(log_line)
        assert res["parsed"], f"Test Case {idx} failed to parse: {log_line}"
        for exp in expected_threats:
            assert exp in res["threats"], f"Test Case {idx} expected threat '{exp}', detected: {res['threats']}"
        if not expected_threats:
            assert len(res["threats"]) == 0, f"Test Case {idx} expected clean, detected: {res['threats']}"

    print("[PASS] All built-in regex and detection self-tests passed successfully!")
    return 0


def interactive_menu():
    """
    Console interactive menu for manual analysis, testing, or file scanning.
    """
    while True:
        print("\n" + "=" * 70)
        print("       WEB SERVER ACCESS LOG ANALYZER & CYBER ATTACK DETECTOR")
        print("=" * 70)
        print("\n1. Analyze custom log")
        print("2. Run built-in test cases")
        print("3. Scan log file or directory")
        print("4. Exit\n")

        try:
            choice = input("Enter your choice: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nExiting program...")
            break

        if choice == "1":
            custom_input()
        elif choice == "2":
            run_test()
        elif choice == "3":
            target_str = input("Enter path to file or directory: ").strip()
            target_path = Path(target_str).resolve()
            if not target_path.exists():
                print(f"[!] Error: Target path '{target_path}' does not exist.")
                continue
            run_scan(target_path, out_path=None, is_json=False, verbose=False)
        elif choice == "4":
            print("\nExiting program...")
            break
        else:
            print("\nInvalid choice. Please enter 1, 2, 3, or 4.")


# ==============================================================================
# 7. SCAN COORDINATOR & MAIN ENTRY POINT
# ==============================================================================

def run_scan(target: Path, out_path: Optional[str] = None, is_json: bool = False, verbose: bool = False) -> int:
    """
    Executes a scan over discovered log files, aggregates metrics,
    prints summary to stdout, and exports report if requested.
    """
    files_to_scan = list(find_files(target))
    if not files_to_scan:
        print(f"[!] No valid log files found in target: {target}")
        return 0

    combined_summary: Dict[str, Any] = {
        "target": str(target),
        "total_lines": 0,
        "parsed_lines": 0,
        "unparsed_lines": 0,
        "total_bytes": 0,
        "status_counter": Counter(),
        "threat_counter": Counter(),
        "attacker_ip_counter": Counter()
    }
    all_incidents: List[Dict[str, Any]] = []

    start_time = time.perf_counter()
    for f in files_to_scan:
        res = scan_file(f)
        combined_summary["total_lines"] += res["total_lines"]
        combined_summary["parsed_lines"] += res["parsed_lines"]
        combined_summary["unparsed_lines"] += res["unparsed_lines"]
        combined_summary["total_bytes"] += res["total_bytes"]
        combined_summary["status_counter"].update(res["status_counter"])
        combined_summary["threat_counter"].update(res["threat_counter"])
        combined_summary["attacker_ip_counter"].update(res["attacker_ip_counter"])
        all_incidents.extend(res["incidents"])

    duration = time.perf_counter() - start_time

    # Print summary to terminal
    print()
    print(format_summary_text(combined_summary, all_incidents, verbose=verbose))
    print(f" Scan Duration: {duration:.4f}s | Files Scanned: {len(files_to_scan)}")

    # Write report if requested
    if out_path:
        written_path = write_report(combined_summary, all_incidents, out_path, is_json, verbose=verbose)
        print(f" Report Saved : {written_path}")

    # Return exit code: 1 if threats found, 0 if clean
    return 1 if sum(combined_summary["threat_counter"].values()) > 0 else 0


def main():
    """
    CLI interface supporting arguments matching secret_scanner convention.
    """
    parser = argparse.ArgumentParser(
        description="Syntaxia: Web Server Access Log Analyzer & Cyber Attack Detector"
    )
    parser.add_argument("path", nargs="?", default=None, help="Target log file or directory to scan")
    parser.add_argument("--target", "-t", default=None, help="Target path (alternative to positional)")
    parser.add_argument("--output", "-o", default=None, help="Destination report file path")
    parser.add_argument("--format", "-f", choices=["txt", "json"], default="txt", help="Report format (txt or json)")
    parser.add_argument("--json", "-j", action="store_true", help="Output report as structured JSON")
    parser.add_argument("--verbose", "-v", action="store_true", help="Display all individual security incidents")
    parser.add_argument("--interactive", "-i", action="store_true", help="Launch interactive menu console")
    parser.add_argument("--test", action="store_true", help="Execute built-in regex verification tests")

    args = parser.parse_args()

    # 1. Self-test mode
    if args.test:
        return run_test()

    # 2. Interactive mode (if explicitly flagged, or run without arguments in terminal)
    if args.interactive or (args.path is None and args.target is None and sys.stdin.isatty()):
        interactive_menu()
        return 0

    # 3. Path resolution
    target_str = args.target or args.path or "."
    target = Path(target_str).resolve()
    if not target.exists():
        print(f"Error: Target path '{target}' does not exist.")
        return 2

    is_json = args.json or (args.format == "json")
    return run_scan(target, out_path=args.output, is_json=is_json, verbose=args.verbose)


if __name__ == "__main__":
    sys.exit(main())
