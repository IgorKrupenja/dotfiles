#!/usr/bin/env python3
"""Stop hook: a banner when a Claude desktop app session finishes a turn.

The app files finished turns in Notification Centre without a banner, so this hook shows one
through Claude-Notify.app: the session title over the first line of Claude's reply. Clicking it
opens the session in the app. It stays quiet while Claude is the frontmost app, and when the turn
ended with a question, since the app shows its own banner for those.

claude-notify is launched detached from the hook's process group: Claude Code waits for every
process in that group to exit before it marks the turn finished. os.setpgrp() creates a new
process group (without a new session). start_new_session=True would also work but breaks
NSWorkspace.open() by removing the macOS security session context needed to launch other apps.
"""
import glob, json, os, re, subprocess, sys

HOME = os.environ['HOME']
APP = HOME + '/.claude/Claude-Notify.app/Contents/MacOS/claude-notify'
SESSIONS = HOME + '/Library/Application Support/Claude/claude-code-sessions'
CLAUDE_BUNDLE_ID = 'com.anthropic.claudefordesktop'
MAX_LENGTH = 180


def claude_is_frontmost():
    front = subprocess.run(['lsappinfo', 'front'], capture_output=True, text=True).stdout.strip()
    info = subprocess.run(['lsappinfo', 'info', '-only', 'bundleid', front], capture_output=True, text=True).stdout
    return CLAUDE_BUNDLE_ID in info


def ended_with_question(transcript_path):
    try:
        with open(transcript_path, 'rb') as transcript:
            transcript.seek(0, os.SEEK_END)
            transcript.seek(max(0, transcript.tell() - 2_000_000))
            lines = transcript.read().decode(errors='ignore').splitlines()
    except (OSError, TypeError):
        return False
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        content = (entry.get('message') or {}).get('content')
        blocks = [block for block in content if isinstance(block, dict)] if isinstance(content, list) else []
        if entry.get('type') == 'assistant':
            for block in blocks:
                if block.get('type') == 'tool_use' and block.get('name') == 'mcp__ccd_turn__wrap_up':
                    return bool((block.get('input') or {}).get('ask'))
        elif entry.get('type') == 'user' and not entry.get('isMeta'):
            if not any(block.get('type') == 'tool_result' for block in blocks):
                return False
    return False


def session_title(session_id):
    for path in glob.glob(f'{SESSIONS}/*/*/{session_id}.json'):
        with open(path) as session:
            return json.load(session).get('title') or 'Claude Code'
    return 'Claude Code'


def first_line(text):
    for line in text.splitlines():
        line = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', line)
        line = re.sub(r'\*\*|__|`', '', line)
        line = re.sub(r'^\s*(#+|>|[-*]|\d+\.)\s+', '', line).strip()
        if line:
            return line if len(line) <= MAX_LENGTH else line[:MAX_LENGTH - 3].rsplit(' ', 1)[0] + '...'
    return 'Finished'


def main():
    session_id = os.environ.get('CLAUDE_CODE_HOST_SESSION_ID')
    if os.environ.get('CLAUDE_CODE_ENTRYPOINT') != 'claude-desktop' or not session_id or claude_is_frontmost():
        return
    hook = json.load(sys.stdin)
    if ended_with_question(hook.get('transcript_path')):
        return
    title = session_title(session_id)
    message = first_line(hook.get('last_assistant_message') or '')
    url = f'claude://claude.ai/epitaxy/{session_id}'
    subprocess.Popen(
        [APP, title, message, 'Glass', CLAUDE_BUNDLE_ID, url],
        preexec_fn=os.setpgrp,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


main()
