# Claude instructions

## No em dashes

Never use the em dash (—, U+2014) in anything you write: chat replies, drafts of messages and emails, posts, documents, code comments, commit messages. This holds in every language, Russian and Estonian included. A spaced en dash ( – ) used as a stand-in counts as the same thing. Rephrase, or use a comma, colon, period or parentheses.

Text Igor sends to other people (DMs, emails, posts) is the strictest case: check every draft for the character before handing it over. He calls this a big problem.

## Dotfiles

Dotfiles repo is at `~/Projects/dotfiles`.

## Commit and push without asking

In every git repo, commit each finished change and push it right away. Don't wait for Igor to ask:
he finds being asked every time annoying. The one exception is the work repo `liqd-casino`
(`~/Projects/liqd-casino`), where you commit and push only when he asks.

- Commit on the current branch and push that branch. Don't create branches or PRs unless asked.
- Stage only the files of your own change. Leave unrelated uncommitted work (another session's,
  say) alone and mention it.
- Follow the repo's commit message style. Never commit secrets (`.env` values, keys, tokens) or
  git-ignored files; check the staged diff before pushing, above all in public repos.
- If the push is rejected because the remote moved, `git pull --rebase` and push again. On a
  conflict, stop and tell Igor.
- A repo's own CLAUDE.md can add checks on top of this, and they still apply.

## Browser automation

The Playwright MCP is only set up in `~/.claude/skills`, for the browser skills there. Everywhere else, use `playwright-cli` through Bash: it's installed globally with bun, and the `playwright-cli` skill lists its commands.

`playwright-cli` saves snapshots and screenshots into `.playwright-cli/` in the current folder (the global gitignore excludes it). A bare `--filename` writes to the current folder instead, so either omit it or keep the path inside that folder: `--filename=.playwright-cli/after-fix.png`, not `--filename=after-fix.png`.

## Playwright MCP output files

Whenever a Playwright MCP tool takes a `filename` parameter, always prefix it with `.playwright-mcp/` (the server's default output folder) so files don't end up in repo roots. Example: `.playwright-mcp/my-shot.jpeg`, not `my-shot.jpeg`.

This applies to every tool with a `filename`, not just screenshots: `browser_take_screenshot`, `browser_snapshot` and `browser_evaluate` all accept one, and accessibility snapshots are the worst offenders (600+ line YAML dumps). Omitting `filename` is also fine: the server then writes into `.playwright-mcp/` by itself.
