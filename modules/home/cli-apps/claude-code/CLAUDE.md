In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

When working in a repository use the agentlocal directory to store ephemeral files.

## Jira

- When given or asked about a Jira ticket use the `acli` cli tool to retrieve its contents:

    # Examples
    # command format:
    # $ acli jira workitem view [key] [flags]

    # View work item with work item keys
    $ acli jira workitem view KEY-123

    # View work item by reading work item keys from a JSON file
    $ acli jira workitem view KEY-123 --json

    # View work item with work item keys and a list of field to return
    $ acli jira workitem view KEY-123 --fields summary,comment

## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI.

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## Shell

- `rm` is aliased to interactive mode; use `rm -f` to bypass in scripts.
