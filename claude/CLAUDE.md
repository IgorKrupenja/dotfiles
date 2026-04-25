# Claude instructions

## Dotfiles

Dotfiles repo is at `~/Projects/dotfiles`.

## Playwright MCP screenshots

When using `mcp__playwright__browser_take_screenshot` with the `filename` parameter, always prefix with `.playwright-mcp/` (the server's default snapshot folder) so files don't end up in repo roots. Example: `.playwright-mcp/my-shot.jpeg`, not `my-shot.jpeg`.
