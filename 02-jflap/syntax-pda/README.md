# Arithmetic Expression & Parentheses Syntax Validator (Pushdown Automaton)

A formal, deterministic 4-state **Pushdown Automaton (PDA)** designed in **JFLAP 7.1** that validates the syntactic correctness of arithmetic expressions with arbitrary nested parentheses and chained parenthesized sub-expressions.

---

## 1. Formal Language Specification

The PDA recognizes the context-free language $L$ of well-formed arithmetic expressions over the alphabet $\Sigma = \{a, b, c, +, -, *, /, (, )\}$:

$$L = \{ w \in \Sigma^* \mid w \text{ is a syntactically valid infix arithmetic expression with balanced parentheses} \}$$

### Syntactic Validity Rules:
1. **Balanced Parentheses**: Every opening bracket `(` must have a matching closing bracket `)` with strictly non-negative nesting depth throughout evaluation.
2. **Valid Infix Syntax**:
   - Expressions cannot be empty ($\varepsilon$).
   - Expressions cannot begin or end with a binary operator (e.g., `+a`, `*a`, `a+`).
   - Consecutive operators are prohibited (e.g., `a++b`, `a*-b`).
   - Empty parentheses are prohibited (e.g., `()`).
   - Operands and parentheses must be explicitly joined by operators (e.g., `a(b)`, `(a)b` are invalid).
3. **Chained & Nested Expressions**:
   - Supports arbitrary nesting depth (e.g., `((a+b))`, `((a-b)/(c+a))`).
   - Fully supports consecutive independent parenthesized expressions (e.g., `(a+b)*(c-a)`), where the stack empties back to the base marker $Z$ between terms.

---

## 2. 4-State Machine Architecture

The machine is structured around **exactly 4 states**, each with a distinct invariant:

```
 (q0: Initial) ── '(' [push (Z] ──> (q1: Needs Operand) <── Operator [keep] ── (q2: Post-Operand) ── ε [pop Z, push Z] ──> ((q3: Final))
       │                                  │        ▲                                │      ▲
       │                                  │        │                                │      │
       └── Operand [keep Z] ──────────────┼────────┘                                └── ')' [pop (] ──┘
                                          │
                                       Operand [keep] ──> (q2)
```

### State Semantics:
- **$q_0$ (Initial State)**: Ready to start the expression. The stack contains only the bottom marker $z_0$ ($Z$). Transitions to $q_1$ on encountering an opening bracket `(`, or to $q_2$ on reading an initial operand (`a`, `b`, `c`).
- **$q_1$ (Needs Operand / Inside Open Bracket)**: Entered after an operator or an opening bracket. In this state, an operand or a nested open bracket is strictly required:
  * Reads a nested `(` to self-loop on $q_1$ (pushes `(` onto stack).
  * Reads an operand (`a`, `b`, `c`) to advance to $q_2$ (stack unchanged).
- **$q_2$ (Post-Operand / Needs Operator or Close Bracket)**: Entered after an operand has been successfully read or a bracket has been closed:
  * Reads an operator (`+`, `-`, `*`, `/`) to return to $q_1$ (stack unchanged).
  * Reads `)` to pop a matching `(` from the stack (self-loop on $q_2$).
  * Consumes $\varepsilon$ ($\lambda$) when the stack top is $z_0$ ($Z$) to advance to acceptance state $q_3$.
- **$q_3$ (Final State)**: Accepting state (`<final/>`). Entered only when the full expression has been consumed and all opened parentheses have been matched.

---

## 3. Formal Machine Definition (7-Tuple)

The Pushdown Automaton $M$ is formally defined as:

$$M = (Q, \Sigma, \Gamma, \delta, q_0, z_0, F)$$

where:
- **$Q = \{q_0, q_1, q_2, q_3\}$**: Finite set of control states.
- **$\Sigma = \{a, b, c, +, -, *, /, (, )\}$**: Finite input alphabet.
- **$\Gamma = \{(, z_0\}$**: Finite stack alphabet (using JFLAP's single-character initial stack marker $Z$).
  - `(`: Pushed to record an open bracket.
  - $z_0$ ($Z$): Initial bottom-of-stack marker.
- **$q_0 \in Q$**: Initial start state.
- **$z_0 \in \Gamma$**: Initial stack symbol (represented as `Z` in JFLAP).
- **$F = \{q_3\}$**: Set of final accepting states (acceptance by final state with base marker preserved).
- **$\delta: Q \times (\Sigma \cup \{\varepsilon\}) \times \Gamma \to Q \times \Gamma^*$**: Transition function.

---

## 4. Standard Textbook Transition Function ($\delta$)

All transition rules strictly follow the standard textbook convention where the stack top is replaced by a string of symbols whose **leftmost character is the new top of the stack**:

$$\delta(q_{\text{current}}, \text{input}, \text{current\_stack\_top}) = (q_{\text{next}}, \text{new\_stack\_string})$$

- **Push**: $\delta(q_i, '(', X) = (q_j, (X)$ (replaces $X$ with $(X$, making `(` the new stack top).
- **Keep / Unchanged**: $\delta(q_i, \text{sym}, X) = (q_j, X)$ (replaces $X$ with $X$, leaving the stack top unchanged).
- **Pop**: $\delta(q_i, ')', '(') = (q_j, \varepsilon)$ (erases `(` from the stack top).
- **Accept**: $\delta(q_2, \varepsilon, z_0) = (q_3, z_0)$ (transitions to final state when input is exhausted and stack is balanced).

### Complete Enumeration of Transitions:

#### Transitions from $q_0$ (Initial State)
At $q_0$, the stack contains strictly the initial marker $z_0$:
1. $\delta(q_0, '(', z_0) = (q_1, (z_0)$ — Open bracket pushed over base marker; advances to $q_1$.
2. $\delta(q_0, 'a', z_0) = (q_2, z_0)$ — Initial operand `'a'` consumed; stack unchanged; advances to $q_2$.
3. $\delta(q_0, 'b', z_0) = (q_2, z_0)$ — Initial operand `'b'` consumed; stack unchanged; advances to $q_2$.
4. $\delta(q_0, 'c', z_0) = (q_2, z_0)$ — Initial operand `'c'` consumed; stack unchanged; advances to $q_2$.

#### Transitions from $q_1$ (Needs Operand / Inside Open Bracket)
In $q_1$, the stack top may be `(` (if inside brackets) or $z_0$ (if following a top-level operator):
5. $\delta(q_1, '(', '(') = (q_1, ((')$ — Nested open bracket pushed over existing `(`; loops on $q_1$.
6. $\delta(q_1, '(', z_0) = (q_1, (z_0)$ — Open bracket pushed over base marker $z_0$; loops on $q_1$.
7. $\delta(q_1, 'a', '(') = (q_2, '(')$ — Operand `'a'` consumed inside brackets; advances to $q_2$.
8. $\delta(q_1, 'a', z_0) = (q_2, z_0)$ — Operand `'a'` consumed at top-level; advances to $q_2$.
9. $\delta(q_1, 'b', '(') = (q_2, '(')$ — Operand `'b'` consumed inside brackets; advances to $q_2$.
10. $\delta(q_1, 'b', z_0) = (q_2, z_0)$ — Operand `'b'` consumed at top-level; advances to $q_2$.
11. $\delta(q_1, 'c', '(') = (q_2, '(')$ — Operand `'c'` consumed inside brackets; advances to $q_2$.
12. $\delta(q_1, 'c', z_0) = (q_2, z_0)$ — Operand `'c'` consumed at top-level; advances to $q_2$.

#### Transitions from $q_2$ (Post-Operand / Needs Operator or Close Bracket)
In $q_2$, an operator returns to $q_1$, a closing bracket pops `(` and stays in $q_2$, and an $\varepsilon$-transition accepts to $q_3$:
13. $\delta(q_2, '+', '(') = (q_1, '(')$ — Operator `'+'` inside brackets; advances to $q_1$.
14. $\delta(q_2, '+', z_0) = (q_1, z_0)$ — Operator `'+'` at top-level; advances to $q_1$.
15. $\delta(q_2, '-', '(') = (q_1, '(')$ — Operator `'-'` inside brackets; advances to $q_1$.
16. $\delta(q_2, '-', z_0) = (q_1, z_0)$ — Operator `'-'` at top-level; advances to $q_1$.
17. $\delta(q_2, '*', '(') = (q_1, '(')$ — Operator `'*'` inside brackets; advances to $q_1$.
18. $\delta(q_2, '*', z_0) = (q_1, z_0)$ — Operator `'*'` at top-level; advances to $q_1$.
19. $\delta(q_2, '/', '(') = (q_1, '(')$ — Operator `'/'` inside brackets; advances to $q_1$.
20. $\delta(q_2, '/', z_0) = (q_1, z_0)$ — Operator `'/'` at top-level; advances to $q_1$.
21. $\delta(q_2, ')', '(') = (q_2, \varepsilon)$ — Closing bracket `')'` pops matching `(`; loops on $q_2$.
22. $\delta(q_2, \varepsilon, z_0) = (q_3, z_0)$ — All input consumed, stack balanced ($z_0$); accepts to $q_3$.

---

## 5. Transition Table

| # | Current State | Input Symbol | Stack Top | Next State | Replacement Stack String | Stack Action | JFLAP XML Representation |
| :-: | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **1** | $q_0$ | `(` | $Z$ | $q_1$ | $(Z$ | Push `(` onto base marker | `<pop>Z</pop><push>(Z</push>` |
| **2** | $q_0$ | `a` | $Z$ | $q_2$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **3** | $q_0$ | `b` | $Z$ | $q_2$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **4** | $q_0$ | `c` | $Z$ | $q_2$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **5** | $q_1$ | `(` | `(` | $q_1$ | `((` | Push nested `(` | `<pop>(</pop><push>((</push>` |
| **6** | $q_1$ | `(` | $Z$ | $q_1$ | $(Z$ | Push `(` onto base marker | `<pop>Z</pop><push>(Z</push>` |
| **7** | $q_1$ | `a` | `(` | $q_2$ | `(` | Keep stack top `(` | `<pop>(</pop><push>(</push>` |
| **8** | $q_1$ | `a` | $Z$ | $q_2$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **9** | $q_1$ | `b` | `(` | $q_2$ | `(` | Keep stack top `(` | `<pop>(</pop><push>(</push>` |
| **10** | $q_1$ | `b` | $Z$ | $q_2$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **11** | $q_1$ | `c` | `(` | $q_2$ | `(` | Keep stack top `(` | `<pop>(</pop><push>(</push>` |
| **12** | $q_1$ | `c` | $Z$ | $q_2$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **13** | $q_2$ | `+` | `(` | $q_1$ | `(` | Keep stack top `(` | `<pop>(</pop><push>(</push>` |
| **14** | $q_2$ | `+` | $Z$ | $q_1$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **15** | $q_2$ | `-` | `(` | $q_1$ | `(` | Keep stack top `(` | `<pop>(</pop><push>(</push>` |
| **16** | $q_2$ | `-` | $Z$ | $q_1$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **17** | $q_2$ | `*` | `(` | $q_1$ | `(` | Keep stack top `(` | `<pop>(</pop><push>(</push>` |
| **18** | $q_2$ | `*` | $Z$ | $q_1$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **19** | $q_2$ | `/` | `(` | $q_1$ | `(` | Keep stack top `(` | `<pop>(</pop><push>(</push>` |
| **20** | $q_2$ | `/` | $Z$ | $q_1$ | $Z$ | Keep stack top $Z$ | `<pop>Z</pop><push>Z</push>` |
| **21** | $q_2$ | `)` | `(` | $q_2$ | $\varepsilon$ | Pop matching `(` | `<pop>(</pop><push/>` |
| **22** | $q_2$ | $\varepsilon$ | $Z$ | $q_3$ | $Z$ | Accept (reach final state) | `<read/><pop>Z</pop><push>Z</push>` |

---

## 6. Instantaneous Description (ID) Step-by-Step Traces

An Instantaneous Description is denoted by $(q, w, \alpha)$ where:
- $q$: Current machine state.
- $w$: Unconsumed input string.
- $\alpha$: Current stack contents (top of stack is leftmost).

### Trace 1: Chained Expressions `(a+b)*(c-a)`
Demonstrates handling of consecutive independent parenthesized sub-expressions where the stack empties to $Z$ mid-computation:
$$(q_0, \mathbf{(a+b)*(c-a)}, Z) \vdash (q_1, \mathbf{a+b)*(c-a)}, (Z) \quad [\text{Rule 1: Read '(', push '(Z')]$$
$$\vdash (q_2, \mathbf{+b)*(c-a)}, (Z) \quad [\text{Rule 7: Read 'a', stack unchanged}]$$
$$\vdash (q_1, \mathbf{b)*(c-a)}, (Z) \quad [\text{Rule 13: Read '+', stack unchanged}]$$
$$\vdash (q_2, \mathbf{)*(c-a)}, (Z) \quad [\text{Rule 9: Read 'b', stack unchanged}]$$
$$\vdash (q_2, \mathbf{*(c-a)}, Z) \quad [\text{Rule 21: Read ')', pop '('}]$$
$$\vdash (q_1, \mathbf{(c-a)}, Z) \quad [\text{Rule 18: Read '*', stack unchanged}]$$
$$\vdash (q_1, \mathbf{c-a)}, (Z) \quad [\text{Rule 6: Read '(', push '(Z')]$$
$$\vdash (q_2, \mathbf{-a)}, (Z) \quad [\text{Rule 11: Read 'c', stack unchanged}]$$
$$\vdash (q_1, \mathbf{a)}, (Z) \quad [\text{Rule 15: Read '-', stack unchanged}]$$
$$\vdash (q_2, \mathbf{)}, (Z) \quad [\text{Rule 7: Read 'a', stack unchanged}]$$
$$\vdash (q_2, \varepsilon, Z) \quad [\text{Rule 21: Read ')', pop '('}]$$
$$\vdash (q_3, \varepsilon, Z) \quad [\text{Rule 22: Read } \varepsilon, \text{ accept in final state } q_3]$$
**Result: ACCEPTED in $q_3 \in F$.**

---

### Trace 2: Mixed Infix Expression `a+(b-c)`
$$(q_0, \mathbf{a+(b-c)}, Z) \vdash (q_2, \mathbf{+(b-c)}, Z) \quad [\text{Rule 2: Read 'a', stack unchanged}]$$
$$\vdash (q_1, \mathbf{(b-c)}, Z) \quad [\text{Rule 14: Read '+', stack unchanged}]$$
$$\vdash (q_1, \mathbf{b-c)}, (Z) \quad [\text{Rule 6: Read '(', push '(Z')]$$
$$\vdash (q_2, \mathbf{-c)}, (Z) \quad [\text{Rule 9: Read 'b', stack unchanged}]$$
$$\vdash (q_1, \mathbf{c)}, (Z) \quad [\text{Rule 15: Read '-', stack unchanged}]$$
$$\vdash (q_2, \mathbf{)}, (Z) \quad [\text{Rule 11: Read 'c', stack unchanged}]$$
$$\vdash (q_2, \varepsilon, Z) \quad [\text{Rule 21: Read ')', pop '('}]$$
$$\vdash (q_3, \varepsilon, Z) \quad [\text{Rule 22: Read } \varepsilon, \text{ reach final state } q_3]$$
**Result: ACCEPTED in $q_3 \in F$.**

---

### Trace 3: Nested Parentheses `((a+b))`
$$(q_0, \mathbf{((a+b))}, Z) \vdash (q_1, \mathbf{(a+b))}, (Z) \quad [\text{Rule 1: Read '(', push '(Z')]$$
$$\vdash (q_1, \mathbf{a+b))}, ((Z) \quad [\text{Rule 5: Read '(', push '(('}]$$
$$\vdash (q_2, \mathbf{+b))}, ((Z) \quad [\text{Rule 7: Read 'a', stack unchanged}]$$
$$\vdash (q_1, \mathbf{b))}, ((Z) \quad [\text{Rule 13: Read '+', stack unchanged}]$$
$$\vdash (q_2, \mathbf{))}, ((Z) \quad [\text{Rule 9: Read 'b', stack unchanged}]$$
$$\vdash (q_2, \mathbf{)}, (Z) \quad [\text{Rule 21: Read ')', pop '('}]$$
$$\vdash (q_2, \varepsilon, Z) \quad [\text{Rule 21: Read ')', pop '('}]$$
$$\vdash (q_3, \varepsilon, Z) \quad [\text{Rule 22: Read } \varepsilon, \text{ reach final state } q_3]$$
**Result: ACCEPTED in $q_3 \in F$.**

---

### Trace 4: Invalid Expression `(a+b))` (Unmatched Closing Parenthesis)
$$(q_0, \mathbf{(a+b))}, Z) \vdash (q_1, \mathbf{a+b))}, (Z) \vdash (q_2, \mathbf{+b))}, (Z) \vdash (q_1, \mathbf{b))}, (Z) \vdash (q_2, \mathbf{))}, (Z)$$
$$\vdash (q_2, \mathbf{)}, Z) \quad [\text{Rule 21: Read ')', pop '('}]$$
$$\vdash \text{CRASH / REJECT} \quad [\text{No transition defined for } \delta(q_2, ')', Z)]$$
**Result: REJECTED (Machine crashes on unexpected stack top).**

---

### Trace 5: Invalid Expression `((a+b)` (Unmatched Opening Parenthesis)
$$(q_0, \mathbf{((a+b)}, Z) \vdash (q_1, \mathbf{(a+b)}, (Z) \vdash (q_1, \mathbf{a+b)}, ((Z) \vdash (q_2, \mathbf{+b)}, ((Z) \vdash (q_1, \mathbf{b)}, ((Z) \vdash (q_2, \mathbf{)}, ((Z)$$
$$\vdash (q_2, \varepsilon, (Z) \quad [\text{Rule 21: Read ')', pop '('}]$$
$$\vdash \text{CRASH / REJECT} \quad [\text{Input is empty; } \delta(q_2, \varepsilon, '(') \text{ is undefined; } q_2 \notin F]$$
**Result: REJECTED (Cannot transition to } q_3 \text{ while unclosed brackets remain on stack).**

---

## 7. Test Suite

### Valid Test Cases (Accepted)

| # | Input String | Expected Result | Acceptance Derivation Summary |
| :-: | :--- | :---: | :--- |
| **1** | `a` | **ACCEPT** | Single identifier; $q_0 \to q_2 \xrightarrow{\varepsilon} q_3$. |
| **2** | `a+b` | **ACCEPT** | Binary addition; alternates operand $\to$ operator $\to$ operand. |
| **3** | `a+(b-c)` | **ACCEPT** | Operand followed by bracketed sub-expression. |
| **4** | `(a+b)*c` | **ACCEPT** | Parenthesized sum multiplied by variable; stack balances at `)`. |
| **5** | `((a-b)/(c+a))` | **ACCEPT** | Nested parentheses with depth 2; stack reaches `((Z`, cleanly pops to $Z$. |
| **6** | `(a+b)*(c-a)` | **ACCEPT** | Consecutive bracketed expressions separated by binary operator. |
| **7** | `((a+b))` | **ACCEPT** | Redundant double brackets; depth 2 stack balance. |
| **8** | `a+b*c` | **ACCEPT** | Multi-operator expression without parentheses. |
| **9** | `(a)` | **ACCEPT** | Minimal enclosed expression; pushes `(`, consumes `a`, pops `(`. |
| **10** | `a*(b+c)-a` | **ACCEPT** | Mixed operator precedence and bracketed sub-expression. |

---

### Invalid Test Cases (Rejected)

| # | Input String | Expected Result | Reason for Rejection |
| :-: | :--- | :---: | :--- |
| **1** | `(a+)` | **REJECT** | Incomplete sub-expression; $q_1$ encounters `)` inside bracket where operand is required. |
| **2** | `*a` | **REJECT** | Leading operator; $q_0$ rejects binary operators without preceding operand. |
| **3** | `a++b` | **REJECT** | Consecutive operators; $q_1$ encounters second operator where operand is required. |
| **4** | `()` | **REJECT** | Empty brackets; $q_1$ reads `)` directly after `(`, where only operands or `(` are permitted. |
| **5** | `(a+b))` | **REJECT** | Extra closing parenthesis; machine in $q_2$ encounters `)` with stack top $Z$ and crashes. |
| **6** | `((a+b)` | **REJECT** | Unclosed bracket; machine halts in $q_2$ with `(` still on stack; cannot reach $q_3$. |
| **7** | `a+` | **REJECT** | Dangling trailing operator; machine ends in non-accepting state $q_1$. |
| **8** | `+a` | **REJECT** | Leading operator; $q_0$ has no transition on `+`. |
| **9** | `a(b)` | **REJECT** | Missing operator between operand and bracket; $q_2$ cannot consume `(`. |
| **10** | `)+a` | **REJECT** | Leading closing parenthesis; $q_0$ has no transition on `)`. |
| **11** | `""` (empty) | **REJECT** | Empty string; machine begins in non-accepting state $q_0$ with no $\varepsilon$-transition. |

---

## 8. How to Run & Simulate in JFLAP 7.1

1. **Launch JFLAP 7.1**:
   ```bash
   java -jar JFLAP7.1.jar
   ```
2. **Open Model File**:
   - Go to **File** $\to$ **Open...**
   - Select `02-jflap/syntax-pda/parentheses_syntax_pda.jff`.
   - The 4-state Pushdown Automaton ($q_0, q_1, q_2, q_3$) will load in a horizontal layout.
3. **Step-by-Step Simulation**:
   - Go to **Input** $\to$ **Step with Closure...** (or **Step by State...**).
   - Enter any test string (e.g. `(a+b)*(c-a)` or `a+(b-c)`).
   - Click **Step** to trace state changes and stack push/pop operations in real-time.
4. **Batch Testing**:
   - Go to **Input** $\to$ **Multiple Run**.
   - Load the test vectors from Section 7 above.
   - Click **Run Inputs** to verify that all valid strings are **Accepted** and all invalid strings are **Rejected**.
