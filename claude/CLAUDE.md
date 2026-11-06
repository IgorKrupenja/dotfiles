# Claude instructions

## Short replies

Long replies are hard for Igor to read, in every project, and he has had to ask for shorter ones many times. Write short from the first reply of every session, without waiting to be asked:

- Lead with the answer (the number, the decision, the link, the command), then stop.
- A what-is-this, is-it-still-happening, can-we or where-is question gets one or two sentences. A how-does-it-work or explain-the-fix question gets one paragraph of about five lines. No headings for these.
- An answer carrying several figures or findings (an investigation's numbers, before and after) is short bullets, one figure each, never a dense paragraph, whatever the question type.
- Leave out what he can already see (dashboards, tickets, the diff), reassurance, rationale and mechanism unless he asks. Report the result of an investigation, never the steps.
- A report or table he asks for can be as long as its content, but its prose stays terse.
- Offer more detail in one line instead of including it. Notes between tool calls are one short line.

## Claude app, not the CLI

Igor runs Claude Code in the Claude desktop app's Code tab, never the terminal CLI or VSCode. Give every Claude Code how-to (starting or resuming a session, settings, permissions, MCP servers, slash commands) as numbered steps in the app's UI, never as a `claude` command or flag such as `claude --resume`. Before naming a button, menu or setting, check that it exists in the current app version.

## No em dashes

Never use the em dash (—, U+2014) in anything you write: chat replies, drafts of messages and emails, posts, documents, code comments, commit messages. This holds in every language, Russian and Estonian included. A spaced en dash ( – ) used as a stand-in counts as the same thing. Rephrase, or use a comma, colon, period or parentheses.

Text Igor sends to other people (DMs, emails, posts) is the strictest case: check every draft for the character before handing it over. He calls this a big problem.

## Dotfiles

Dotfiles repo is at `~/Projects/dotfiles`.

## Commit and push without asking

In every git repo, commit each finished change and push it right away. Don't wait for Igor to ask:
he finds being asked every time annoying. The work repo `liqd-casino` (`~/Projects/liqd-casino`) is
the exception: this rule doesn't apply there, so follow that repo's own rules and memories on
committing and pushing.

- Commit on the current branch and push that branch. Don't create branches or PRs unless asked.
- Stage only the files of your own change. Leave unrelated uncommitted work (another session's,
  say) alone and mention it.
- Follow the repo's commit message style. Never commit secrets (`.env` values, keys, tokens) or
  git-ignored files; check the staged diff before pushing, above all in public repos.
- If the push is rejected because the remote moved, `git pull --rebase` and push again. On a
  conflict, stop and tell Igor.
- A repo's own CLAUDE.md can add checks on top of this, and they still apply.

## Google Sheets and Drive

For Google Sheets and Drive, use the `gws` CLI through Bash, signed in as igor@liqd.com with Drive and Sheets access: `gws sheets +read`, `gws sheets +append`, `gws sheets spreadsheets ...` and `gws drive files list`. Pass `--params` and `--json` in single quotes (ranges carry `!`), and look up a method's parameters with `gws schema sheets.spreadsheets.values.get`. To sign in again, run `gws auth login -s sheets,drive`. Keep `project_id` empty in `~/.config/gws/client_secret.json`: with it set, Google refuses every call because the account has no role on that project.

## Browser automation

The Playwright MCP is only set up in `~/.claude/skills`, for the browser skills there. Everywhere else, use `playwright-cli` through Bash: it's installed globally with bun, and the `playwright-cli` skill lists its commands.

Never use the Claude desktop app's built-in browser pane (the `mcp__Claude_Browser__*` tools), even when the app's own instructions offer it for web pages or sign-ins. Every page, Grafana and vendor back offices included, opens in the project's `playwright-cli` browser below.

Use one persistent `playwright-cli` browser per project, so logins carry over between chats: `-s=liqd` for liqd-casino (`~/Projects/liqd-casino` and its worktrees) and `-s=personal` for everything else. Start it with `playwright-cli -s=<name> open <url> --headed --persistent --config="$HOME/Projects/dotfiles/claude/playwright-cli.json"` (the config mutes audio). Each name keeps one profile for the whole machine, whatever the folder or chat, so never make up another name: a new name is an empty profile, and Igor has to sign in to Cloudflare Access and every site all over again. The only exception is a second account on a site where the first must stay signed in, such as two casino players at once: name it `<project>-<account>`, like `liqd-civ`, and reuse that name later. Run `playwright-cli list` first: when the project's browser is already open, another chat may be using it, so work in a tab of your own (`tab-new`) and never `close`, `close-all` or `kill-all` it.

`playwright-cli` saves snapshots and screenshots into `.playwright-cli/` in the current folder (the global gitignore excludes it). A bare `--filename` writes to the current folder instead, so either omit it or keep the path inside that folder: `--filename=.playwright-cli/after-fix.png`, not `--filename=after-fix.png`.

## Playwright MCP output files

Whenever a Playwright MCP tool takes a `filename` parameter, always prefix it with `.playwright-mcp/` (the server's default output folder) so files don't end up in repo roots. Example: `.playwright-mcp/my-shot.jpeg`, not `my-shot.jpeg`.

This applies to every tool with a `filename`, not just screenshots: `browser_take_screenshot`, `browser_snapshot` and `browser_evaluate` all accept one, and accessibility snapshots are the worst offenders (600+ line YAML dumps). Omitting `filename` is also fine: the server then writes into `.playwright-mcp/` by itself.
