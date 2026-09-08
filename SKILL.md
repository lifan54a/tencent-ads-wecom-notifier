---
name: tencent-ads-wecom-skill
description: Install, test, operate, or troubleshoot a Windows automation that polls Tencent Ads Leads Platform and sends new-lead notifications to a WeCom group robot. Use when a user wants Tencent Ads lead alerts without a public HTTPS receiver, or needs help with this notifier's credentials, scheduled task, silent execution, message fields, or authentication failures.
---

# Tencent Ads to WeCom

Use the bundled PowerShell helpers in this skill directory to operate a polling-based Tencent Ads lead notifier on Windows.

## Install

Before installation, confirm that the user authorizes querying their Tencent Ads leads and sending the requested lead fields to their chosen WeCom group. Do not ask the user to paste Token, Secret, or Webhook values into chat. Run `install.ps1` in an interactive terminal so the user enters all three values through hidden prompts.

The installer must complete these outcomes:

1. Store credentials locally in ignored encrypted configuration files.
2. Test Tencent Ads authentication without exposing lead details.
3. Send a generic WeCom connectivity message.
4. Install `TencentAdsLeadToWeCom` as a one-minute Windows scheduled task.
5. Launch PowerShell through `run-hidden.vbs` so polling creates no visible console window.

If the user only wants a connectivity check, run `test.ps1`. For status, run `status.ps1`. For removal, run `uninstall.ps1`; removal intentionally retains local encrypted credentials unless the user explicitly asks to delete them.

## Operating constraints

- Prefer the HTTPS endpoint `https://leads.qq.com/api/mv1/leads/list` even if an older UI displays HTTP.
- Treat `config.secure.json`, `config.key`, `state.json`, and logs as private local state. Never commit, publish, print, or include them in a release archive.
- Never print response bodies containing names, phone numbers, addresses, IDs, or form answers during testing or troubleshooting.
- Preserve `leads_id` de-duplication and the overlapping polling window when modifying the implementation.
- Tencent Leads Platform Token/Secret are static credentials in the published API guide; there is no documented refresh endpoint. Generate a fresh timestamp, nonce, and signature for each request. If authentication fails, report it and have the user rerun configuration rather than inventing automatic renewal.
- Sending full names or phone numbers requires the user's explicit authorization for the destination group. Otherwise use masked phone numbers and omit direct identifiers.
- The local scheduled task requires Windows, network access, and the installing user to be logged in. For always-on operation without a PC, propose a scheduled cloud function. For true push delivery, explain that Tencent Ads POST forwarding requires a public HTTPS receiver.

For authentication, request fields, pagination, response handling, and error codes, read [references/tencent-leads-api.md](references/tencent-leads-api.md).

## Validate changes

After modifying scripts, parse every `.ps1` file with the Windows PowerShell parser. Run `poll-leads.ps1 -TestOnly` before installing or replacing the scheduled task. A successful test must send only a generic connection message and must not advance `state.json`.

When preparing a shareable archive, run `build-package.ps1` and inspect the ZIP entries for forbidden credential and state filenames before publishing.

