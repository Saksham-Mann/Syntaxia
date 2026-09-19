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

DFAs accept precisely the class of **Regular Languages (Chomsky Type-3)**.

---

### 2. Pushdown Automata (PDA)
A PDA extends a finite automaton with an unbounded Last-In, First-Out (LIFO) stack, enabling the recognition of **Context-Free Languages (Chomsky Type-2)**:
$$M = (Q, \Sigma, \Gamma, \delta, q_0, Z_0, F)$$
where:
- $\Gamma$: Finite stack alphabet
- $Z_0 \in \Gamma$: Initial stack symbol
- $\delta: Q \times (\Sigma \cup \{\varepsilon\}) \times \Gamma \to \mathcal{P}(Q \times \Gamma^*)$: Transition function governing state changes and stack push/pop operations.

---

## Planned Projects

### 1. `syntax-pda/` (Pushdown Automaton)
- **Objective**: Design and simulate a PDA that recognizes syntactically balanced nested expressions containing parentheses `()`, square brackets `[]`, curly braces `{}`, and binary operators (`+`, `-`, `*`, `/`).
- **Deliverables**:
  - `syntax_checker.jff`: JFLAP XML state machine file.
  - `state_table.md`: Comprehensive transition table documenting each $(q, a, X) \to (p, \alpha)$ step.
  - Acceptance traces for valid and invalid expression vectors.

---

### 2. `literal-lexer-dfa/` (Deterministic Finite Automaton)
- **Objective**: Construct a minimal DFA recognizing programming language literals:
  - Decimal Integers: `[0-9]+`
  - Floating Point (with optional exponent): `[0-9]+\.[0-9]+([eE][+-]?[0-9]+)?`
  - Hexadecimal: `0[xX][0-9a-fA-F]+`
  - Quoted Strings with escape sequences: `"([^"\\]|\\.)*"`
- **Deliverables**:
  - `literal_lexer.jff`: JFLAP DFA specification.
  - `transition_matrix.md`: State transition table and dead-state analysis.
  - Step-by-step simulation logs for boundary test cases.

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
3. Open any `.jff` model file (`File -> Open`) to view state graphs, run step-by-step simulations, or run fast batch tests against multiple inputs.
