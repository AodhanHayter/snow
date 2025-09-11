When given or asked about a Jira ticket use the `acli` cli tool to retrieve its contents:

    # Examples
    # command format:
    # $ acli jira workitem view [key] [flags]

    # View work item with work item keys
    $ acli jira workitem view KEY-123

    # View work item by reading work item keys from a JSON file
    $ acli jira workitem view KEY-123 --json

    # View work item with work item keys and a list of field to return
    $ acli jira workitem view KEY-123 --fields summary,comment
