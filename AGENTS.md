# Home-level agent instructions

## Secrets

- Never print, echo, or log secret values (API keys, tokens, passwords) in chat, logs, or command output.
- Load secrets into environment variables instead of reading them into the conversation. For example:
  `export MY_TOKEN="$(pass path/to/secret)"`
- In tests, only perform basic checks on secrets: non-empty, expected length, or expected format. Never assert on or print the full value.
