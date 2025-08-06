---
description: Create a set of unit tests for the given file, function, class, or module.
---

## Your task

Based on the $ARGUMENTS provided, create a set of unit tests for the given file, function, class, or module

## Steps to follow

1. Based on the $ARGUMENTS, determine if you are writing tests for a file, function, class, or module.

2. Find the relevant code in the repository. NEVER write tests until you are 95% sure you've found the correct piece of code. Stop what you're doing and notify the user if you cannot find the referenced code.

3. Determine the correct place to add testing code. Examine other nearby files to determine where to place test files for the code in question.

4. Write the tests according to the best practices below

5. Run the tests to ensure they pass. If you cannot run the tests, notify the user and provide the tests anyway.

## Best Practices

- Write small focused tests that are isolated, independent, and deterministic.
- Ensure the tests are easy to read, understand, and maintain.
- Only mock or stub when absolutely necessary.
- Prefer to test only the public API of code, avoiding private or internal implementation details.
