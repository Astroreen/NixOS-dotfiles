# Example Command

Description

- A simple example command demonstrating the expected structure and usage for commands in this project.

Command

- `example-command`

Synopsis

- `example-command [--input <file>] [--format json|yaml]`

Arguments

- `--input <file>`: Path to the input file to process. Optional; if omitted, reads from stdin.
- `--format`: Output format. Defaults to `json`.

Environment

- `EXAMPLE_API_KEY`: Optional API key used by the command (set in `.env` or environment).

Examples

- Read a file and output JSON:

    example-command --input ./data.txt --format json

- Read from stdin and output YAML:

    cat ./data.txt | example-command --format yaml

Expected output

- On success: writes the processed result to stdout in the requested format and exits with code `0`.
- On failure: writes an error message to stderr and exits with a non-zero code.

Notes

- Keep secrets out of version control; use `.env` or environment variables.
- Use this file as a template when adding new commands to the `commands/` folder.
