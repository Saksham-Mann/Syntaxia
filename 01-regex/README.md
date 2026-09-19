# 01-regex: Regular Expressions & Pattern Recognition

This module explores **Type-3 Regular Languages** within the Chomsky Hierarchy, focusing on regular expressions as operational specifications for Finite State Automata (DFA/NFA) and their practical implementation in high-speed pattern recognition systems.

---

## Theoretical Foundations

### 1. Kleene's Theorem & Equivalence
According to **Kleene's Theorem**, any language that can be described by a regular expression can also be recognized by a:
- **Non-deterministic Finite Automaton (NFA)**, and by subset construction, a
- **Deterministic Finite Automaton (DFA)**.

$$\mathcal{L}(\text{Regex}) \equiv \mathcal{L}(\text{NFA}) \equiv \mathcal{L}(\text{DFA})$$

### 2. Regular Language Operations
A regular language over an alphabet $\Sigma$ is closed under:
1. **Union** ($R_1 \cup R_2$ or `R1|R2`)
2. **Concatenation** ($R_1 \cdot R_2$ or `R1R2`)
3. **Kleene Star** ($R^*$ or `R*`)
4. **Complement** and **Intersection**

### 3. The ReDoS Hazard & Safe Pattern Engineering
Python's standard library `re` uses an NFA-based backtracking engine. If a regular expression exhibits overlapping paths with unbounded repetition (e.g., `(a+)+b` matched against `"aaaaac"`), the engine evaluates exponential branches ($O(2^n)$), causing **Catastrophic Backtracking** or **ReDoS (Regular Expression Denial of Service)**.

#### Mitigation Strategies Used in Syntaxia:
- **Bounded Quantifiers**: Replace open-ended `+` or `*` with finite ranges `{min,max}` (e.g., `[0-9a-zA-Z]{24,99}`).
- **Anchor Lookarounds**: Use zero-width assertions `(?<!...)` and `(?![...])` to enforce token boundaries without consuming characters or creating backtracking branch points.
- **Non-Capturing Groups**: Utilize `(?:...)` instead of `(...)` when captured values are unnecessary, avoiding internal memory tracking and backreference overhead.
- **Precompilation**: All patterns are compiled via `re.compile()` at module load time for single-pass transition table generation.

---

## Projects in this Module

### [Project 1: Secret Scanner (`secret-scanner/`)](secret-scanner/)
A zero-dependency Python scanner that inspects codebases, `.env` files, YAML manifests, and JSON configs for leaked sensitive tokens and API keys.

- **Detections**: AWS Access Keys, AWS Secret Keys, GitHub Classic & Fine-Grained PATs, Stripe Live/Test API Keys, Slack Tokens, and Generic Assigned Passwords.
- **Features**: Safe lookaround boundaries, ReDoS immunity, automated masking (`AKIA************MPLE`), and JSON/Text report generation.

```bash
# Run self-tests
python 01-regex/secret-scanner/secret_scanner.py --test

# Scan sample fixtures
python 01-regex/secret-scanner/secret_scanner.py 01-regex/secret-scanner/fixtures
```

---

### [Project 2: Log Analyzer (`log-analyzer/`)](log-analyzer/)
A high-throughput log parser and security threat analyzer specification that tokenizes web server logs (Nginx, Apache Combined/Common Log Format) and authentication records.

- **Detections**: SQL Injection attempts (`UNION SELECT`, `' OR '1'='1`), Directory Traversal / LFI (`../`, `/etc/passwd`), Cross-Site Scripting (`<script>`, `onerror=`), sensitive file probes (`.env`, `wp-login.php`, `.git`), and anomalous error rates.
- **Features**: Structured token extraction (IP, timestamp, HTTP method, URI, status, response size, referer, user-agent), IP frequency aggregation, HTTP status breakdown, and JSON reporting.
- **Specification**: See [01-regex/log-analyzer/README.md](log-analyzer/README.md) for full architecture and regular expression patterns.
