# Automated Secret & API Key Leak Scanner

A lightweight Python scanner that uses only the standard library `re` module to find leaked API keys, tokens, and passwords in your code and configuration files.

---

## What It Detects

| Secret Type | What It Matches | Example Masked Output |
| :--- | :--- | :--- |
| **AWS Access Key ID** | 20-character AWS keys starting with `AKIA` | `AKIA************MPLE` |
| **AWS Secret Access Key** | 40-character base64 keys assigned to AWS variables | `wJal********************************EKEY` |
| **GitHub Classic PAT** | 40-character classic GitHub tokens starting with `ghp_` | `ghp_********************************8B4a` |
| **GitHub Fine-Grained PAT** | Scoped GitHub tokens starting with `github_pat_` | `gith********************************...6789` |
| **Stripe API Key** | Stripe keys starting with `sk_live_`, `pk_test_`, etc. | `sk_l********************************...0ABC` |
| **Slack Token** | Slack bot and user tokens starting with `xoxb-`, `xoxa-` | `xoxb********************************...uvwx` |
| **Generic Credentials** | Hardcoded passwords or API keys assigned via `=` or `:` | `d9f8************************5f4a` |

*Note: Trivial dummy values like `"password123"`, `"TODO"`, and `"CHANGE_ME"` are automatically ignored to avoid false alarms.*

---

## How to Run the Program

The script has **zero external dependencies**. You only need Python 3 installed.

### Basic Syntax
```bash
python secret_scanner.py [TARGET_PATH] [OPTIONS]
```

### Available Command Line Options

| Option | Shorthand | Default | Description |
| :--- | :--- | :--- | :--- |
| `--target` | `-t` | `.` (current folder) | Folder or single file path you want to scan |
| `--output` | `-o` | `secret_scan_report.txt` | File path where the findings report will be saved |
| `--format` | `-f` | `txt` | Report format: choose either `txt` or `json` |
| `--json` | | | Shortcut to export the report as JSON |
| `--test` | | | Runs quick built-in regex verification checks |

---

## Sample Test Cases (Using the `fixtures/` Folder)

The project includes a `fixtures/` folder containing realistic test files in different formats:

- `fixtures/.env` - Environment file with leaked AWS, Stripe, Slack, and GitHub keys.
- `fixtures/config.json` - JSON file with quoted keys (`api_key`, `github_pat`).
- `fixtures/deployment.yaml` - Kubernetes deployment file with a Stripe secret.
- `fixtures/client.js` - JavaScript file with a Stripe publishable key.
- `fixtures/clean_service.py` - Clean Python file that uses environment variables safely (0 leaks).

Here is how to run each test case correctly:

### Test Case 1: Scan the Entire `fixtures/` Folder
Scans all 5 sample files and saves a detailed text report:
```bash
python secret_scanner.py fixtures --output secret_scan_report.txt
```
**Expected Terminal Output:**
```text
============================================================
           SECRET SCAN SUMMARY
============================================================
Target       : .../Secret Scanner - Regex/fixtures
Duration     : 0.0039s
Files Scanned: 5
Leaks Found  : 10
Report File  : .../Secret Scanner - Regex/secret_scan_report.txt
Status       : FAILED - LEAKS DETECTED
============================================================
```
*The script finds all 10 real leaks, ignores dummy values like `"password123"` and `"TODO"`, saves the report, and exits with code `1`.*

---

### Test Case 2: Scan a Single File (`fixtures/.env`)
You can pass a specific file path instead of a folder:
```bash
python secret_scanner.py fixtures/.env --output env_report.txt
```
**What happens:**
Only `fixtures/.env` is scanned. Findings from that file are saved to `env_report.txt`.

---

### Test Case 3: Scan a Clean File (`fixtures/clean_service.py`)
Tests how the scanner behaves when code follows security best practices (reading secrets from `os.getenv`):
```bash
python secret_scanner.py fixtures/clean_service.py
```
**Expected Terminal Output:**
```text
============================================================
           SECRET SCAN SUMMARY
============================================================
Target       : .../Secret Scanner - Regex/fixtures/clean_service.py
Duration     : 0.0011s
Files Scanned: 1
Leaks Found  : 0
Report File  : None (Clean)
Status       : PASSED - CLEAN
============================================================
```
*The scan passes cleanly with 0 leaks, creates no report file, and exits with status code `0`.*

---

### Test Case 4: Export Report in JSON Format
If you need machine-readable output for CI/CD pipelines or automated tools:
```bash
python secret_scanner.py fixtures --json --output report.json
```
**What happens:**
Generates `report.json` containing a structured JSON summary and an array of findings with file paths, line numbers, and masked secrets.

---

### Test Case 5: Run Built-In Self-Test
Verifies that the regex rules and masking function are working properly:
```bash
python secret_scanner.py --test
```
**Expected Terminal Output:**
```text
[PASS] Built-in regex and masking tests passed.
```

---

## Sample Report Format (`secret_scan_report.txt`)

When secrets are detected, the report gives only the necessary details:

```text
======================================================================
SECRET SCAN AUDIT REPORT
======================================================================
Target: .../fixtures | Files Scanned: 5 | Leaks Found: 10 | Time: 0.0039s
======================================================================

[1] AWS Access Key ID
  Relative Path : .env
  Absolute Path : C:\...\fixtures\.env
  Line Number   : 4
  Masked Secret : AKIA************MPLE
  Sanitized Line: AWS_ACCESS_KEY_ID=AKIA************MPLE
----------------------------------------------------------------------
[2] AWS Secret Access Key
  Relative Path : .env
  Absolute Path : C:\...\fixtures\.env
  Line Number   : 5
  Masked Secret : wJal********************************EKEY
  Sanitized Line: AWS_SECRET_ACCESS_KEY=wJal********************************EKEY
----------------------------------------------------------------------
[3] Stripe API Key
  Relative Path : client.js
  Absolute Path : C:\...\fixtures\client.js
  Line Number   : 4
  Masked Secret : pk_t*******************************************0ABC
  Sanitized Line: const stripePublishableKey = "pk_t*******************************************0ABC";
----------------------------------------------------------------------
```

---

## Exit Codes for CI/CD Pipelines

- **Code `0`**: Clean (no secrets or leaks found).
- **Code `1`**: Leaks detected (one or more credentials flagged).
- **Code `2`**: Invalid target path provided.
