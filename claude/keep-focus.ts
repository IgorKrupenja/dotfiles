#!/usr/bin/env bun
/**
 * Run a command that starts a headed browser, and hand focus back to the app that was in front
 * the moment the browser takes it. macOS brings Chrome to the front when Playwright starts it, and
 * Playwright's pipe to Chrome rules out a background start through LaunchServices, so this is as
 * close to a background launch as it gets: the window shows for a fraction of a second.
 *
 *     bun ~/Projects/dotfiles/claude/keep-focus.ts playwright-cli -s=personal open <url> --headed --persistent --config=…
 *
 * skills-kit's browser.ts does the same for the skills repos' browsers.
 */

/** The Chromium browsers playwright-cli can open: Chrome in any channel, Chromium and Edge. */
const BROWSER_APP = /^(com\.google\.chrome|org\.chromium|com\.microsoft\.edge)/i;

/** The bundle ID of the app in front, from LaunchServices; "" when it has none. */
function frontApp(): string {
  const run = (cmd: string[]) => Bun.spawnSync(cmd).stdout.toString();
  return run(["lsappinfo", "info", "-only", "bundleID", run(["lsappinfo", "front"]).trim()]).match(/bundleID="([^"]+)"/)?.[1] ?? "";
}

const command = Bun.argv.slice(2);
if (!command.length) {
  console.error("usage: keep-focus.ts <command> [args…]");
  process.exit(2);
}

const before = frontApp();
const proc = Bun.spawn(command, { stdio: ["inherit", "inherit", "inherit"] });
if (before && !BROWSER_APP.test(before)) {
  let exitedAt = 0;
  proc.exited.then(() => { exitedAt = performance.now(); });
  // Watch until a second after the command is done, in case the window comes up late.
  while (!exitedAt || performance.now() - exitedAt < 1000) {
    const front = frontApp();
    if (front !== before && BROWSER_APP.test(front)) {
      Bun.spawnSync(["open", "-b", before]);
      await Bun.sleep(300); // let the switch land before looking again
    } else {
      await Bun.sleep(40);
    }
  }
}
process.exit(await proc.exited);
