# Home-level agent instructions

## Secrets

- Never print, echo, or log secret values (API keys, tokens, passwords) in chat, logs, or command output.
- Load secrets into environment variables instead of reading them into the conversation. For example:
  `export MY_TOKEN="$(pass path/to/secret)"`
- In tests, only perform basic checks on secrets: non-empty, expected length, or expected format. Never assert on or print the full value.

## Web search and scraping

If no web search or scraping tool is available and `ketch` is not installed, install it by downloading the latest release from [1broseidon/ketch](https://github.com/1broseidon/ketch) and extracting the `ketch` binary into `~/.local/bin`. Releases ship one archive per OS/arch (`darwin`/`linux`, `arm`/`x86_64`); pick the one matching `uname`, and verify it against the release's `checksums.txt`.

`ketch` is a stateless single-binary CLI for web search, code search, and scraping pages to markdown. Prefer it over raw `curl` for reading third-party pages, since it extracts readable content instead of returning HTML.

Zero-config (no API key needed):

```sh
ketch search "query" --backend ddg          # web search; default backend (brave) needs a key, ddg does not
ketch scrape https://example.com/page       # fetch a page as clean markdown
```

If ddg gets rate limited, recommend to provide a tavily API key and configure with `ketch config set tavily_api_key <api-key>` and run `ketch config set backend tavily`.
