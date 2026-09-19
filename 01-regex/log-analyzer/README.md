# Syntaxia: High-Performance Web & System Log Analyzer

A lightweight, zero-dependency Python log parsing and cybersecurity threat detection engine using Python's standard library `re` module. Demonstrates the application of **regular expressions as deterministic tokenizers** and security pattern discriminators.

---

## Features & Detections

### 1. Structured Token Extraction
Parses **Nginx / Apache Combined & Common Log Format** and **Linux Syslog / Auth logs** into structured dictionaries using compiled regular expressions with named capture groups `(?P<name>...)`:
- Client IP address (IPv4 / IPv6)
- Timestamp
- HTTP Verb (`GET`, `POST`, `PUT`, `DELETE`, etc.)
- Request URI / Resource Endpoint / Query parameters
- HTTP Protocol Version
- HTTP Response Status Code (`200`, `301`, `404`, `500`, etc.)
- Bytes Transferred
- Referer URL
- User-Agent header

### 2. Regex-Based Threat & Anomaly Detection

| Threat Category | Target Field | Detection Strategy & Regex Signature |
| :--- | :--- | :--- |
| **SQL Injection (SQLi)** | Request URI / Params | Unquoted URI scanning for `UNION SELECT`, `OR '1'='1'`, `information_schema`, `--` comments, and sleep/benchmark injections. |
| **Path Traversal / LFI** | Request URI / Path | Detects `../`, `..%2f`, and attempts to access `/etc/passwd`, `/proc/self/environ`, or `win.ini`. |
| **Cross-Site Scripting (XSS)** | Query String / POST | Matches `<script>` tags, `javascript:` pseudoprotocols, event handlers (`onerror=`, `onload=`), and `alert()` calls. |
| **Sensitive File Probing** | Request URI | Detects reconnaissance probes for `/.env`, `/.git`, `/wp-login.php`, `/phpmyadmin`, `/actuator/heapdump`, and database backups. |
| **Malicious Scanner UAs** | User-Agent | Flags automated penetration tools including `sqlmap`, `nikto`, `nmap`, `masscan`, `acunetix`, `dirbuster`, and `gobuster`. |
| **Auth Brute Force** | Syslog / Auth message | Identifies repeated SSH `Failed password` attempts and unauthorized user login attacks. |

---

## How to Run

### Basic Syntax
```bash
python log_analyzer.py [TARGET_PATH] [OPTIONS]
```

### Command-Line Flags

| Option | Flag | Default | Description |
| :--- | :--- | :--- | :--- |
| Target | positional | `.` (current folder) | Single `.log` file or directory containing log files |
| Output Path | `-o`, `--output` | None (stdout) | Destination file path for generated report |
| JSON Format | `-j`, `--json` | `False` | Export output in structured JSON format |
| Verbose | `-v`, `--verbose` | `False` | Display all individual security incident records |
| Test Mode | `--test` | `False` | Executes built-in regex rule verification tests |

---

## Test Cases (Using `fixtures/`)

### Test Case 1: Run Built-In Self-Tests
Validates all compiled regular expressions, parsing routines, and threat patterns:
```bash
python log_analyzer.py --test
```
**Expected Output:**
```text
[*] Running built-in self-tests for LogAnalyzer...
[PASS] All built-in regex and detection self-tests passed successfully!
```

---

### Test Case 2: Scan Web Server Access Log (`fixtures/access.log`)
Scans multi-vector attack scenarios and HTTP metrics:
```bash
python log_analyzer.py fixtures/access.log
```
**Expected Terminal Output:**
```text
======================================================================
               SYNTAXIA LOG & THREAT ANALYZER REPORT
======================================================================
 Total Lines Processed : 18
 Successfully Parsed   : 18 (100.0%)
 Unparsed / Raw Lines  : 0
 Bandwidth Transferred : 0.03 MB
 Security Incidents    : 14
----------------------------------------------------------------------
 HTTP STATUS CODE DISTRIBUTION
----------------------------------------------------------------------
  2xx Success       : 9
  3xx Redirection   : 1
  4xx Client Error  : 7
  5xx Server Error  : 1
----------------------------------------------------------------------
 DETECTED CYBERSECURITY THREATS
----------------------------------------------------------------------
  [!] SQL Injection (SQLi)                :     2 incident(s)
  [!] Malicious Scanner / Exploit Tool UA :     5 incident(s)
  [!] Cross-Site Scripting (XSS)          :     1 incident(s)
  [!] Directory Traversal / LFI           :     2 incident(s)
  [!] Sensitive File Probing              :     4 incident(s)

 TOP ATTACKER IP ADDRESSES:
  - 203.0.113.88                   : 10 incident(s)
  - 198.51.100.42                  : 4 incident(s)
======================================================================
```

---

### Test Case 3: Scan Authentication Logs (`fixtures/auth.log`)
Analyzes SSH login patterns and flags credential brute force attacks:
```bash
python log_analyzer.py fixtures/auth.log
```

---

### Test Case 4: Verify Clean Traffic (`fixtures/clean.log`)
Validates that legitimate web traffic produces 0 false positives:
```bash
python log_analyzer.py fixtures/clean.log
```
**Expected Output:**
```text
 DETECTED CYBERSECURITY THREATS
----------------------------------------------------------------------
  [CLEAN] No threats or intrusion signatures detected.
```

---

### Test Case 5: Export JSON Report for SIEM / Automated Pipeline
```bash
python log_analyzer.py fixtures/access.log --json -o report.json
```

---

## Regular Expression Engineering & ReDoS Safety

1. **Named Capture Groups**: We employ `(?P<group_name>pattern)` to construct clear, zero-copy semantic records from raw log streams.
2. **Elimination of Catastrophic Backtracking**:
   - Every wildcard quantifier is strictly bounded (e.g. `[\s\S]{1,50}` instead of `.*`).
   - Repetition anchors use possessive/atomic concepts and word boundaries `\b` to prevent state explosion when parsing maliciously crafted long URIs.
3. **URL Decoding**: The analyzer performs standard `urllib.parse.unquote()` before token inspection so attackers cannot bypass regex filters via percent-encoding (`%20UNION%20SELECT`).
