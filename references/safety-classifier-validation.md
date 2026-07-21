# Safety Classifier Validation

Use this when a proposed edit changes code that decides whether an operation is a read, write, destructive action, authenticated action, or confirmation-gated action.

## Core asymmetry

A conservative classifier may have annoying false positives, but replacing it with a parser-like scanner can introduce false negatives that bypass the safety gate. Treat the change as security-sensitive even when the motivating bug is only “this harmless read asks for confirmation.”

## Minimum paired gate

Validate the exact candidate against both sides:

1. **Benign negatives:** the sensitive keyword in strings, block strings, comments, aliases, operation names, fragment names, nested fields, and variable values must not trigger the gate.
2. **Dangerous positives:** real gated operations must still trigger when preceded by fragments, comments, multiple definitions, variables, directives, and escaped string delimiters.
3. **Escape parity:** for delimiter scanners, test odd and even runs of escape characters immediately before the delimiter. Odd/even parity bugs commonly turn a real closer into escaped content or vice versa.
4. **Malformed input:** choose and test a fail-closed behavior when the classifier cannot establish the operation type safely.
5. **Causal execution:** run one bounded live read and one no-side-effect positive control proving the dangerous operation is blocked before network or mutation.
6. **Exact-head review:** after fixing a review finding, rerun tests and re-review the new commit. A PASS on the pre-fix head is not transferable.

## Worked pattern

A whole-document keyword regex correctly caught every dangerous operation but also matched the keyword inside a harmless string. Replacing it with a structural scanner fixed the false positive, then review found an even/odd backslash bug around triple-quoted block strings that could hide a later operation keyword. The durable lesson is not the specific syntax. It is that a safety-gate refactor must preserve conservative coverage while narrowing false positives, and adversarial delimiter tests belong in the first candidate rather than after review.

## Stopping rule

One shared root fix plus one focused regression test is enough when the paired gate passes. Do not add duplicated warnings to the skill text when the executable classifier is the defect.
