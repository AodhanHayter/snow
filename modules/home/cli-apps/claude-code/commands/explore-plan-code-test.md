---
description: A command for exploring, planning, coding, and testing a new feature or bugfix.
---

At the end of this message, I will have a specific task for you.
Always follow the "Explore, Plan, Code, Test" workflow when you start.

# Explore
First, use parallel subagents to find and read all files that may be useful for implenting the task, either as examples or
as targets for editing. The subagents should return relevant file paths and any other info that may be useful.

If the codebase is large utilize the Gemini CLI tool too assist with exploration. Rules for its usage can be found in the specialized exploration tools section below.

## Specialized exploration tools

### Gemini CLI

Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed context limits, use the Gemini CLI with its massive
context window. Use `gemini -p` to leverage Google Gemini's large context capacity.

**File and Directory Inclusion Syntax**

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the
  gemini command:

**Examples:**

**Single file analysis:**
`gemini -p "@src/main.py Explain this file's purpose and structure"`

Multiple files:
`gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"
`
Entire directory:
`gemini -p "@src/ Summarize the architecture of this codebase"
`
Multiple directories:
`gemini -p "@src/ @tests/ Analyze test coverage for the source code"
`
Current directory and subdirectories:
`gemini -p "@./ Give me an overview of this entire project"`


Or use --all_files flag:
`gemini --all_files -p "Analyze the project structure and dependencies"
`
Implementation Verification Examples

Check if a feature is implemented:
`gemini -p "@src/ @lib/ Has dark mode been implemented in this codebase? Show me the relevant files and functions"`

Verify authentication implementation:
`gemini -p "@src/ @middleware/ Is JWT authentication implemented? List all auth-related endpoints and middleware"
`
Check for specific patterns:
`gemini -p "@src/ Are there any React hooks that handle WebSocket connections? List them with file paths"`

Verify error handling:
`gemini -p "@src/ @api/ Is proper error handling implemented for all API endpoints? Show examples of try-catch blocks"`

Check for rate limiting:
`gemini -p "@backend/ @middleware/ Is rate limiting implemented for the API? Show the implementation details"`

Verify caching strategy:
`gemini -p "@src/ @lib/ @services/ Is Redis caching implemented? List all cache-related functions and their usage"
`
Check for specific security measures:
`gemini -p "@src/ @api/ Are SQL injection protections implemented? Show how user inputs are sanitized"
`
Verify test coverage for features:
`gemini -p "@src/payment/ @tests/ Is the payment processing module fully tested? List all test cases"
`
When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results

# Plan
Think hard and write up a detailed implementation plan. Always include possible abstractions, modules, tests, and documentation.
Use expert judgement as to what is is most necessary, given the standards of this codebase.

If there are things you are unsure about, use parallel subagents to do research on the web. They should only return relevant
and useful information, never return irrelevant or low-quality information.

If there are things you still do not understand or questions you have for the user, pause here to ask them before continuing.

# Code
When you have a thorough implementation plan, you are allowed to start writing code. Follow the style of the existing codebase.
Make sure to utilize any linting or formatting commands as part of the coding process. Always attempt to fix any linter or language
server warnings or errors before finishing.

# Test
Use parallel subagents to run tests, and make sure they all pass. Never make a test pass by disabling or changing required functionality.

If your changes are related to UI/UX in a major way, use the web browser to make sure that everything works correctly.
Make sure to use the current users default profile as it will be more likely to have an authenticated session. Make a list of what to test for, use a subagent for this step.

If testing reveals problems, go back to the planning stage and think ultrahard.

# Summarize your work
When you believe the task has been completed, write a short report that could be used as a pull request description.
Include the goal of the task, the choices that were made with justification, and any commands you ran in the process
that may be useful for future developers to know about.


