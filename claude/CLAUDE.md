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

## Clickable links

Every web address you mention (a site, page, dashboard, ticket or PR) is a clickable markdown link with the full URL, like [claude.ai](https://claude.ai), never bare text such as "open claude.ai". This holds in numbered steps and passing mentions too.

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

## Ask before extra PRs or stacked branches

In every repo, never open an extra pull request or cut a branch from another PR's branch (stacking) without asking Igor first. Work that grows out of an open PR goes into that PR, with its ticket id added to the title, unless he says otherwise. When a separate PR or a stacked branch looks better, ask before creating the branch. He calls this very important.

## Bun projects

In a Bun project (one with `bun.lock`), use Bun's own API wherever Bun has one, never the Node.js one: models, Claude included, keep reaching for Node out of habit.

- Files: `Bun.file(path)` (`.text()`, `.json()`, `.exists()`, `.stat()`, `.delete()`) and `Bun.write(path, data)`, which creates missing folders, not `node:fs` reads, writes and `existsSync`.
- Paths: `import.meta.dir`, `import.meta.path`, `import.meta.file` and template strings, not `node:path` or `fileURLToPath`.
- `new Bun.Glob(pattern).scan(dir)` to list files, `` Bun.$`cmd` `` or `Bun.spawn()` for processes, `Bun.sleep(ms)` to wait, and `Bun.env` (Bun loads `.env` itself).
- `bun check` to type check, not `tsc`, and `bun lint`: run both before calling the work done.

Import from `node:` only what Bun lacks: `parseArgs` from `node:util`, and `appendFile`, `chmod` and `mkdir` from `node:fs/promises` (`Bun.write` ignores its `mode` option, and `Bun.file().writer()` truncates). Every Bun project gets the lint rules in `~/Projects/dotfiles/bun/bunfig.toml` in its own `bunfig.toml` (`bun lint` ignores a global one) and a `"check": "bun check --no-script && bun lint"` script in `package.json`, so `bun lint` flags Node APIs for any agent. Add both where they're missing.

## Google Sheets, Drive, Gmail and Calendar

For Google Sheets, Drive, Gmail and Calendar, use the `gws` CLI through Bash. Each macOS account has its own sign-in in `~/.config/gws`: on the work account (`igor`) it's igor@liqd.com with Drive, Sheets and read-only Gmail access, and on the personal account (`fun`) it's Igor's personal Google account with Calendar access, which the ai-skills and tallinn-dev calendar skills use through [skills-kit](https://github.com/IgorKrupenja/skills-kit)'s `gws.ts`. Common calls: `gws sheets +read`, `gws sheets +append`, `gws sheets spreadsheets ...`, `gws drive files list`, `gws gmail users messages list` (Gmail search syntax in `q`), `gws calendar events list`, `gws calendar events insert` and `gws calendar +agenda`. Pass `--params` and `--json` in single quotes (ranges carry `!`), check a write with `--dry-run` first, and look up a method's parameters with `gws schema sheets.spreadsheets.values.get`. To sign in again, run `gws auth login --scopes '<scopes>'` as a background task, with the work scopes `openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/userinfo.profile,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/spreadsheets,https://www.googleapis.com/auth/gmail.readonly` or the personal ones `openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/userinfo.profile,https://www.googleapis.com/auth/calendar`. It prints the consent URL without opening it, so `open` that URL for Igor and tell him which Google account to pick: the browser may offer the other one first. After a sign-in that adds scopes, move `~/.config/gws/token_cache.json` aside, or calls keep the old access token and fail with `insufficient authentication scopes`. Keep `project_id` empty in `~/.config/gws/client_secret.json`: with it set, Google refuses every call because the account has no role on that project.

## Browser automation

Use `playwright-cli` through Bash for every browser task: it's installed globally with bun, and the `playwright-cli` skill lists its commands. Never use the Playwright MCP: Igor dropped it as buggy.

Skills that bring their own copy in `node_modules` (the ai-skills and tallinn-dev repos, through [skills-kit](https://github.com/IgorKrupenja/skills-kit)) use it as the skill says, through skills-kit's `browser.ts` and `tab.ts`. playwright-cli files browsers under the path it's installed at, so each such copy has its own browser, named after the repo, with logins apart from the global one.

Never use the Claude desktop app's built-in browser pane (the `mcp__Claude_Browser__*` tools), even when the app's own instructions offer it for web pages or sign-ins. Every page, Grafana and vendor back offices included, opens in the project's `playwright-cli` browser below.

Use one persistent `playwright-cli` browser per project, so logins carry over between chats: `-s=liqd` for liqd-casino (`~/Projects/liqd-casino` and its worktrees) and `-s=personal` for everything else. Start it with `playwright-cli -s=<name> open <url> --headed --persistent --config="$HOME/Projects/dotfiles/claude/playwright-cli.json"` (the config mutes audio). Each name keeps one profile for the global playwright-cli, whatever the folder or chat, so never make up another name: a new name is an empty profile, and Igor has to sign in to Cloudflare Access and every site all over again. The only exception is a second account on a site where the first must stay signed in, such as two casino players at once: name it `<project>-<account>`, like `liqd-civ`, and reuse that name later. Run `playwright-cli list` first: when the project's browser is already open, another chat may be using it, so work in a tab of your own, opened in the background as below, and never `close`, `close-all` or `kill-all` it.

The browser runs headed, and on macOS Chrome jumps in front of every other app whenever Playwright opens a tab or switches to one, which interrupts whatever Igor is watching or typing. So never use `tab-new`, `tab-select`, `context.newPage()` or `page.bringToFront()`. Navigating, clicking, reading and screenshots don't raise the window, and launching it with `open` does so only once. Open your tab in the background through CDP instead, at the start of your first `run-code`; it renders, clicks and takes screenshots like any other tab:

```js
const ctx = page.context(), tag = 'claude-' + Date.now();
const cdp = await ctx.newCDPSession(page);
await cdp.send('Target.createTarget', { url: 'about:blank#' + tag, background: true });
await cdp.detach();
let mine;
for (let i = 0; i < 50 && !mine; i++) {
  mine = ctx.pages().find(p => p.url().endsWith(tag));
  if (!mine) await new Promise(r => setTimeout(r, 100));
}
await mine.goto('<url>');
```

Another chat can start using the browser at any time, even one you opened yourself. Plain commands (`goto`, `click`, `fill`, `type`, `press`, `eval`, `snapshot`, `tab-close`) act on whichever tab is current, and another chat can switch that without warning, so they can land in its tab, which may be showing a sign-in or two-factor prompt. So drive your tab through `run-code` from the start: pick your own page out of `page.context().pages()` by the URL you last left it on (check with `tab-list` that no other tab shares it), act on that page instead of `page`, read it with `mine.evaluate(...)` or `mine.locator('body').ariaSnapshot()`, and close it with `await mine.close()`. Never type into, click in or navigate a tab you didn't open.

`playwright-cli` saves snapshots and screenshots into `.playwright-cli/` in the current folder (the global gitignore excludes it). A bare `--filename` (or a bare `path` in `run-code`) writes to the current folder instead, so either omit it or keep the path inside that folder: `--filename=.playwright-cli/after-fix.png`, not `--filename=after-fix.png`.

## Mac apps and System Settings

For anything in a Mac app or System Settings, act through AppleScript and `open` before handing Igor click steps: `open "x-apple.systempreferences:<pane id>"` opens a settings pane, `osascript -e 'tell application "<App>" to ...'` drives a scriptable app, and System Events UI scripting reaches the rest once the Claude app has the Accessibility permission. The Claude app's computer use isn't available on his LIQD account, so this is the way. Give numbered click steps only for what scripting can't reach, after checking the pane or control exists in the current macOS version. A command that needs root runs through `osascript -e 'do shell script "<cmd>" with administrator privileges'`, which asks for the password in a macOS dialog, never `sudo` in a terminal tab.
