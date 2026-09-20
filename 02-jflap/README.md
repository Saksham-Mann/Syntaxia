# 02-jflap: Automata Modeling with JFLAP

This module focuses on graphical and mathematical modeling of **Finite State Automata** and **Pushdown Automata** using [JFLAP v7.1](https://www.jflap.org/) (Java Formal Languages and Automata Package).

---

## Theoretical Overview

### 1. Deterministic Finite Automata (DFA)
A DFA is a 5-tuple:
$$M = (Q, \Sigma, \delta, q_0, F)$$
where:
- $Q$: Finite set of states
- $\Sigma$: Finite input alphabet
- $\delta: Q \times \Sigma \to Q$: Deterministic state transition function
- $q_0 \in Q$: Initial start state
- $F \subseteq Q$: Set of accepting/final states

DFAs recognize precisely the class of **Regular Languages (Chomsky Type-3)**.

---

### 2. Pushdown Automata (PDA)
A PDA extends a finite automaton with an unbounded Last-In, First-Out (LIFO) stack, enabling the recognition of **Context-Free Languages (Chomsky Type-2)**:
$$M = (Q, \Sigma, \Gamma, \delta, q_0, Z_0, F)$$
where:
- $\Gamma$: Finite stack alphabet
- $Z_0 \in \Gamma$: Initial stack symbol
- $\delta: Q \times (\Sigma \cup \{\varepsilon\}) \times \Gamma \to \mathcal{P}(Q \times \Gamma^*)$: Transition function governing state changes and stack push/pop operations.

---

## Implemented Projects

### 1. [`syntax-pda/`](syntax-pda/) (Arithmetic & Parentheses Syntax PDA)
- **Objective**: A minimal, deterministic 4-state Pushdown Automaton ($q_0, q_1, q_2, q_3$) validating well-formed infix arithmetic expressions and balanced arbitrary nested parentheses over alphabet $\{a, b, c, +, -, *, /, (, )\}$.
- **Deliverables**:
  - `parentheses_syntax_pda.jff`: JFLAP 7.1 PDA state machine file.
  - `README.md`: Formal 7-tuple definition, 22-row transition table, instantaneous description traces, and test suite.

---

### 2. [`literal-lexer-dfa/`](literal-lexer-dfa/) (Numerical Literal Lexer DFA)
- **Objective**: A complete 13-state Deterministic Finite Automaton tokenizing and validating numerical literals across four categories:
  - Decimal Integers: `0`, `42`, `+100`, `-25`
  - Floating-Point: `3.14`, `+0.5`, `.5`, `-.75`
  - Scientific Notation: `1e10`, `2.5E-3`, `0e5`, `+1.2e+4`
  - Hexadecimal Integers: `0x1A`, `0xFF`, `0x10`, `0Xabc`
- **Deliverables**:
  - `literal_lexer_dfa.jff`: JFLAP 7.1 DFA model file.
  - `README.md`: Formal 5-tuple definition, transition matrix table, step-by-step traces, dead-state analysis, and test suite.

---

## Running Simulations in JFLAP

1. Ensure Java Runtime Environment (JRE 8 or later) is installed:
   ```bash
   java -version
   ```
2. Download and launch `JFLAP7.1.jar`:
   ```bash
   java -jar JFLAP7.1.jar
   ```
3. Open any `.jff` model file (`File -> Open...`):
   - `02-jflap/syntax-pda/parentheses_syntax_pda.jff`
   - `02-jflap/literal-lexer-dfa/literal_lexer_dfa.jff`
4. Run simulations:
   - **Step with Closure...** / **Step by State...** for step-by-step interactive tracing.
   - **Multiple Run** for fast batch testing across valid and invalid inputs.
