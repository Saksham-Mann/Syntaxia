# Numerical Literal Lexer (Deterministic Finite Automaton)

A formal, deterministic **13-state Finite Automaton (DFA)** modeled in **JFLAP 7.1** that validates and tokenizes programming language numerical literals, including signed/unsigned decimal integers, floating-point numbers with fractional parts, scientific exponent notation, and hexadecimal integers.

---

## 1. Formal Language Specification

The DFA recognizes the regular language $L_{\text{num}}$ over the alphanumeric and symbolic alphabet:

$$\Sigma = \{0, 1, \dots, 9, a, b, c, d, e, f, A, B, C, D, E, F, x, X, +, -, .\}$$

$$L_{\text{num}} = L_{\text{int}} \cup L_{\text{float}} \cup L_{\text{sci}} \cup L_{\text{hex}}$$

### Supported Numerical Literal Categories:
1. **Decimal Integer Literals ($L_{\text{int}}$)**:
   - Zero: `0`, `+0`, `-0`
   - Non-zero integers: `42`, `+100`, `-25`, `9999`
2. **Floating-Point Literals ($L_{\text{float}}$)**:
   - Standard fractional floats: `3.14`, `+0.5`, `-12.345`
   - Floats with leading decimal point: `.5`, `+.75`, `-.125`
3. **Scientific Notation Literals ($L_{\text{sci}}$)**:
   - Integer mantissa with exponent: `1e10`, `0e5`, `-4E6`
   - Floating-point mantissa with exponent: `2.5E-3`, `+1.2e+4`, `.5e2`
4. **Hexadecimal Literals ($L_{\text{hex}}$)**:
   - Prefix `0x` or `0X` followed by hexadecimal digits (`0-9`, `a-f`, `A-F`): `0x1A`, `0xFF`, `0x10`, `0Xabc`, `0xDEADBEEF`

### Lexical Rejection Rules:
- Isolated signs or points: `+`, `-`, `.`, `+ .`
- Incomplete hex prefixes: `0x`, `0X`
- Trailing decimal points without fractional digits: `1.`, `42.`
- Incomplete exponents: `1e`, `1e+`, `2.5E-`
- Non-hex characters in hex literals: `0xG`, `0x1Z`
- Multiple decimal points: `3.14.15`
- Consecutive signs: `++5`, `--10`

---

## 2. Machine Architecture & State Invariants

The DFA consists of **13 states** ($q_0$ through $q_{11}$ and $q_D$), structured with strict type boundaries:

```text
               ┌─── [1-9] ───────────> (q3: Integer) ── '.' ──> q4 ── [0-9] ──> (q5: Float)
               │                             │                     ▲                │
               │                             └── 'e'/'E' ──┐       │                │ 'e'/'E'
               │                                           │       │                ▼
(q0: Start) ───┼─── '0' ─────────────> (q2: Zero/Prefix) ──┴───────┼───────────> q7: Exp
  │            │                             │                     │                │
  │ '+','-'    │                             ├── 'x'/'X' ──> q10   │                ├── '+','-' ──> q8 ── [0-9] ──┐
  ▼            │                             └── '.' ──────────────┘                │                             ▼
 q1: Sign ─────┴─── '.' ─────────────> q6: Leading Dot ── [0-9] ──> (q5)           └── [0-9] ───────────────> (q9: Sci)
                                                                     │
 (q10: Hex Prefix) ── [0-9,a-f,A-F] ──> ((q11: Hex Digits)) <────────┴── Invalid Chars ──> qD: Trap / Dead
```

### State Semantics:
- **$q_0$ (Start State)**: Initial unconsumed state. Branches on leading signs (`+`, `-`), zero (`0`), non-zero digits (`1-9`), or leading decimal point (`.`).
- **$q_1$ (Signed Start)**: Entered after an initial `+` or `-`. Expects an integer digit (`0`, `1-9`) or leading decimal point (`.`).
- **$q_2$ (Zero / Literal Prefix)** *(Accepting)*: Recognizes `0` (or `+0`, `-0`). Branches to float fraction ($q_4$), scientific exponent ($q_7$), or hexadecimal prefix ($q_{10}$).
- **$q_3$ (Decimal Integer)** *(Accepting)*: Recognizes standard non-zero decimal integers. Self-loops on `0-9`. Branches to decimal point ($q_4$) or exponent ($q_7$).
- **$q_4$ (Decimal Point after Digits)**: Transient state after `.` following integer digits. Requires at least one fractional digit (`0-9`) to advance to $q_5$.
- **$q_5$ (Fractional Floating-Point)** *(Accepting)*: Recognizes valid fractional floating-point numbers. Self-loops on `0-9`. Transitions to exponent on `e`/`E` ($q_7$).
- **$q_6$ (Leading Decimal Point)**: Transient state after `.` with no preceding integer digits (e.g. `.5`). Requires at least one digit (`0-9`) to reach $q_5$.
- **$q_7$ (Exponent Indicator `e`/`E`)**: Transient state after scientific exponent marker. Branches to signed exponent ($q_8$) on `+`/`-`, or directly to exponent digits ($q_9$) on `0-9`.
- **$q_8$ (Signed Exponent)**: Transient state after `+`/`-` following `e`/`E`. Requires exponent digits (`0-9`) to reach $q_9$.
- **$q_9$ (Scientific Float Digits)** *(Accepting)*: Recognizes complete scientific notation numbers. Self-loops on `0-9`.
- **$q_{10}$ (Hexadecimal Prefix `0x`/`0X`)**: Transient state after `0x` or `0X`. Requires at least one hex digit (`0-9`, `a-f`, `A-F`) to reach $q_{11}$.
- **$q_{11}$ (Hexadecimal Digits)** *(Accepting)*: Recognizes complete hexadecimal integer literals. Self-loops on `0-9`, `a-f`, `A-F`.
- **$q_D$ / $q_{12}$ (Dead / Trap State)**: Non-accepting sink state for absorbing invalid lexical characters.

---

## 3. Formal Machine Definition (5-Tuple)

The Deterministic Finite Automaton $M$ is formally defined by the 5-tuple:

$$M = (Q, \Sigma, \delta, q_0, F)$$

where:
- **$Q = \{q_0, q_1, q_2, q_3, q_4, q_5, q_6, q_7, q_8, q_9, q_{10}, q_{11}, q_D\}$**: Finite set of 13 control states.
- **$\Sigma = \{0, 1, \dots, 9, a, \dots, f, A, \dots, F, x, X, +, -, .\}$**: Finite input alphabet.
- **$q_0 \in Q$**: Initial start state.
- **$F = \{q_2, q_3, q_5, q_9, q_{11}\} \subset Q$**: Set of 5 accepting/final states.
  - $q_2$: Zero (`0`, `+0`, `-0`)
  - $q_3$: Decimal Integers (`42`, `+100`)
  - $q_5$: Fractional Floating-Point Numbers (`3.14`, `.5`)
  - $q_9$: Scientific Floating-Point Numbers (`1e10`, `2.5E-3`)
  - $q_{11}$: Hexadecimal Integers (`0x1A`, `0xFF`)
- **$\delta: Q \times \Sigma \to Q$**: Deterministic transition function.

---

## 4. Transition Function Specification ($\delta$)

$$\delta(q_{\text{current}}, \text{input\_symbol}) = q_{\text{next}}$$

### 1. From Initial State $q_0$
- $\delta(q_0, '+') = q_1, \quad \delta(q_0, '-') = q_1$
- $\delta(q_0, '0') = q_2$
- $\delta(q_0, d) = q_3 \quad \forall d \in \{1, \dots, 9\}$
- $\delta(q_0, '.') = q_6$

### 2. From Signed State $q_1$
- $\delta(q_1, '0') = q_2$
- $\delta(q_1, d) = q_3 \quad \forall d \in \{1, \dots, 9\}$
- $\delta(q_1, '.') = q_6$

### 3. From Zero / Prefix State $q_2 \in F$
- $\delta(q_2, '.') = q_4$
- $\delta(q_2, 'e') = q_7, \quad \delta(q_2, 'E') = q_7$
- $\delta(q_2, 'x') = q_{10}, \quad \delta(q_2, 'X') = q_{10}$

### 4. From Decimal Integer State $q_3 \in F$
- $\delta(q_3, d) = q_3 \quad \forall d \in \{0, \dots, 9\}$
- $\delta(q_3, '.') = q_4$
- $\delta(q_3, 'e') = q_7, \quad \delta(q_3, 'E') = q_7$

### 5. From Decimal Point State $q_4$
- $\delta(q_4, d) = q_5 \quad \forall d \in \{0, \dots, 9\}$

### 6. From Fractional Float State $q_5 \in F$
- $\delta(q_5, d) = q_5 \quad \forall d \in \{0, \dots, 9\}$
- $\delta(q_5, 'e') = q_7, \quad \delta(q_5, 'E') = q_7$
- $\delta(q_5, c) = q_D \quad \forall c \in \{+, -, ., x, X, a\dots d, f, A\dots D, F\}$

### 7. From Leading Decimal Point State $q_6$
- $\delta(q_6, d) = q_5 \quad \forall d \in \{0, \dots, 9\}$

### 8. From Exponent Marker State $q_7$
- $\delta(q_7, '+') = q_8, \quad \delta(q_7, '-') = q_8$
- $\delta(q_7, d) = q_9 \quad \forall d \in \{0, \dots, 9\}$

### 9. From Signed Exponent State $q_8$
- $\delta(q_8, d) = q_9 \quad \forall d \in \{0, \dots, 9\}$

### 10. From Scientific Float Digits State $q_9 \in F$
- $\delta(q_9, d) = q_9 \quad \forall d \in \{0, \dots, 9\}$

### 11. From Hex Prefix State $q_{10}$
- $\delta(q_{10}, h) = q_{11} \quad \forall h \in \{0\dots 9, a\dots f, A\dots F\}$

### 12. From Hex Digits State $q_{11} \in F$
- $\delta(q_{11}, h) = q_{11} \quad \forall h \in \{0\dots 9, a\dots f, A\dots F\}$

---

## 5. State Transition Matrix Table

| State | State Type | `+`, `-` | `0` | `1-9` | `.` | `e`, `E` | `x`, `X` | `a-f`, `A-F` (excl. `e`/`E`) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **$q_0$** | Initial | $q_1$ | $q_2$ | $q_3$ | $q_6$ | — | — | — |
| **$q_1$** | Transient | — | $q_2$ | $q_3$ | $q_6$ | — | — | — |
| **$q_2$** | **Final (Zero)** | — | — | — | $q_4$ | $q_7$ | $q_{10}$ | — |
| **$q_3$** | **Final (Integer)** | — | $q_3$ | $q_3$ | $q_4$ | $q_7$ | — | — |
| **$q_4$** | Transient | — | $q_5$ | $q_5$ | — | — | — | — |
| **$q_5$** | **Final (Float)** | $q_D$ | $q_5$ | $q_5$ | $q_D$ | $q_7$ | $q_D$ | $q_D$ |
| **$q_6$** | Transient | — | $q_5$ | $q_5$ | — | — | — | — |
| **$q_7$** | Transient | $q_8$ | $q_9$ | $q_9$ | — | — | — | — |
| **$q_8$** | Transient | — | $q_9$ | $q_9$ | — | — | — | — |
| **$q_9$** | **Final (Scientific)** | — | $q_9$ | $q_9$ | — | — | — | — |
| **$q_{10}$**| Transient | — | $q_{11}$ | $q_{11}$ | — | — | — | $q_{11}$ |
| **$q_{11}$**| **Final (Hex)** | — | $q_{11}$ | $q_{11}$ | — | — | — | $q_{11}$ |
| **$q_D$** | Trap / Dead | — | — | — | — | — | — | — |

*Note: Cells with `—` denote undefined transitions that cause immediate rejection/crash.*

---

## 6. Step-by-Step Execution Traces

### Trace 1: Signed Integer `+42`
$$q_0 \xrightarrow{+} q_1 \xrightarrow{4} q_3 \xrightarrow{2} q_3$$
**Result: ACCEPTED in $q_3 \in F$.**

### Trace 2: Standard Floating-Point `3.14`
$$q_0 \xrightarrow{3} q_3 \xrightarrow{.} q_4 \xrightarrow{1} q_5 \xrightarrow{4} q_5$$
**Result: ACCEPTED in $q_5 \in F$.**

### Trace 3: Float with Leading Decimal Point `.5`
$$q_0 \xrightarrow{.} q_6 \xrightarrow{5} q_5$$
**Result: ACCEPTED in $q_5 \in F$.**

### Trace 4: Scientific Notation `2.5E-3`
$$q_0 \xrightarrow{2} q_3 \xrightarrow{.} q_4 \xrightarrow{5} q_5 \xrightarrow{E} q_7 \xrightarrow{-} q_8 \xrightarrow{3} q_9$$
**Result: ACCEPTED in $q_9 \in F$.**

### Trace 5: Hexadecimal Integer `0x1A`
$$q_0 \xrightarrow{0} q_2 \xrightarrow{x} q_{10} \xrightarrow{1} q_{11} \xrightarrow{A} q_{11}$$
**Result: ACCEPTED in $q_{11} \in F$.**

### Trace 6: Invalid Literal `1.` (Trailing Decimal Point)
$$q_0 \xrightarrow{1} q_3 \xrightarrow{.} q_4$$
**Result: REJECTED ($q_4 \notin F$, no fractional digit supplied).**

### Trace 7: Invalid Literal `0x` (Incomplete Hex Prefix)
$$q_0 \xrightarrow{0} q_2 \xrightarrow{x} q_{10}$$
**Result: REJECTED ($q_{10} \notin F$, no hex digit supplied).**

---

## 7. Comprehensive Test Suite

### Valid Test Cases (Accepted)

| # | Input String | Token Category | Final State | Acceptance Notes |
| :-: | :--- | :--- | :---: | :--- |
| **1** | `0` | Decimal Integer | $q_2$ | Literal zero root |
| **2** | `+0` | Decimal Integer | $q_2$ | Explicitly signed zero |
| **3** | `-0` | Decimal Integer | $q_2$ | Negative signed zero |
| **4** | `42` | Decimal Integer | $q_3$ | Unsigned non-zero integer |
| **5** | `+100` | Decimal Integer | $q_3$ | Positive signed integer |
| **6** | `-25` | Decimal Integer | $q_3$ | Negative signed integer |
| **7** | `3.14` | Floating-Point | $q_5$ | Standard fractional float |
| **8** | `+0.5` | Floating-Point | $q_5$ | Signed fractional float |
| **9** | `-.75` | Floating-Point | $q_5$ | Signed float with leading point |
| **10** | `.5` | Floating-Point | $q_5$ | Unsigned float starting with point |
| **11** | `1e10` | Scientific Float | $q_9$ | Integer mantissa with exponent |
| **12** | `2.5E-3` | Scientific Float | $q_9$ | Float mantissa with negative exponent |
| **13** | `0e5` | Scientific Float | $q_9$ | Zero mantissa with exponent |
| **14** | `+1.2e+4` | Scientific Float | $q_9$ | Signed float with signed exponent |
| **15** | `0x1A` | Hexadecimal | $q_{11}$ | Hex literal with uppercase letter |
| **16** | `0xFF` | Hexadecimal | $q_{11}$ | Byte boundary hex literal |
| **17** | `0x10` | Hexadecimal | $q_{11}$ | Hexadecimal value 16 |
| **18** | `0Xabc` | Hexadecimal | $q_{11}$ | Hex with uppercase prefix & lowercase digits |

---

### Invalid Test Cases (Rejected)

| # | Input String | Expected Result | Rejection Cause |
| :-: | :--- | :---: | :--- |
| **1** | `""` (empty) | **REJECT** | Starts in non-accepting state $q_0$ |
| **2** | `+` | **REJECT** | Halts in non-accepting state $q_1$ (isolated sign) |
| **3** | `-` | **REJECT** | Halts in non-accepting state $q_1$ (isolated sign) |
| **4** | `.` | **REJECT** | Halts in non-accepting state $q_6$ (isolated point) |
| **5** | `0x` | **REJECT** | Halts in non-accepting state $q_{10}$ (missing hex digits) |
| **6** | `1.` | **REJECT** | Halts in non-accepting state $q_4$ (missing fractional digits) |
| **7** | `1e` | **REJECT** | Halts in non-accepting state $q_7$ (missing exponent digits) |
| **8** | `1e+` | **REJECT** | Halts in non-accepting state $q_8$ (missing signed exponent digits) |
| **9** | `++5` | **REJECT** | Crash at $q_1$ on second `+` |
| **10** | `0xx` | **REJECT** | Crash at $q_{10}$ on invalid character `x` |
| **11** | `3.14.15` | **REJECT** | Transitions to trap state $q_D$ on second decimal point |
| **12** | `0xG` | **REJECT** | Crash at $q_{10}$ on non-hexadecimal character `G` |

---

## 8. How to Run & Simulate in JFLAP 7.1

1. **Launch JFLAP 7.1**:
   ```bash
   java -jar JFLAP7.1.jar
   ```
2. **Open Model File**:
   - Navigate to **File** $\to$ **Open...**
   - Select `02-jflap/literal-lexer-dfa/literal_lexer_dfa.jff`.
   - The 13-state automaton graph will load with all labeled transitions.
3. **Step-by-Step Simulation**:
   - Select **Input** $\to$ **Step with Closure...** (or **Step by State...**).
   - Enter test inputs (e.g. `2.5E-3` or `0x1A`).
   - Click **Step** to trace state changes in real time.
4. **Fast Batch Testing**:
   - Select **Input** $\to$ **Multiple Run**.
   - Input the test cases from Section 7.
   - Click **Run Inputs** to confirm all valid inputs show **Accept** and invalid inputs show **Reject**.
