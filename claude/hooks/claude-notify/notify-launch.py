#!/usr/bin/env python3
"""Launch claude-notify detached from the hook's process group.

Claude Code hooks wait for all processes in the hook's process group to exit
before marking a task as complete. Without detachment, the VSCode extension
stays stuck in "thinking" until claude-notify's 5-minute timeout fires.

os.setpgrp() creates a new process group (without a new session), so Claude
Code no longer waits for claude-notify. Using start_new_session=True would
also work but breaks NSWorkspace.open() by removing the macOS security
session context needed to launch other apps.
"""
import subprocess, os, sys

app = os.environ['HOME'] + '/.claude/Claude-Notify.app/Contents/MacOS/claude-notify'
subprocess.Popen(
    [app] + sys.argv[1:],
    preexec_fn=os.setpgrp,
    stdin=open(os.devnull),
    stdout=open(os.devnull, 'w'),
    stderr=open(os.devnull, 'w'),
)
