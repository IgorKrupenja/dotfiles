# Claude instructions

## No em dashes

Never use the em dash (—, U+2014) in anything you write: chat replies, drafts of messages and emails, posts, documents, code comments, commit messages. This holds in every language, Russian and Estonian included. A spaced en dash ( – ) used as a stand-in counts as the same thing. Rephrase, or use a comma, colon, period or parentheses.

Text Igor sends to other people (DMs, emails, posts) is the strictest case: check every draft for the character before handing it over. He calls this a big problem.

## Dotfiles

Dotfiles repo is at `~/Projects/dotfiles`.

## Browser automation

The Playwright MCP is only set up in `~/.claude/skills`, for the browser skills there. Everywhere else, use `playwright-cli` through Bash: it's installed globally with bun, and the `playwright-cli` skill lists its commands.

`playwright-cli` saves snapshots and screenshots into `.playwright-cli/` in the current folder (the global gitignore excludes it). A bare `--filename` writes to the current folder instead, so either omit it or keep the path inside that folder: `--filename=.playwright-cli/after-fix.png`, not `--filename=after-fix.png`.

## Playwright MCP output files

Whenever a Playwright MCP tool takes a `filename` parameter, always prefix it with `.playwright-mcp/` (the server's default output folder) so files don't end up in repo roots. Example: `.playwright-mcp/my-shot.jpeg`, not `my-shot.jpeg`.

This applies to every tool with a `filename`, not just screenshots: `browser_take_screenshot`, `browser_snapshot` and `browser_evaluate` all accept one, and accessibility snapshots are the worst offenders (600+ line YAML dumps). Omitting `filename` is also fine: the server then writes into `.playwright-mcp/` by itself.
