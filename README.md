# telegram-notify-action

Send a Telegram message from any GitHub Actions workflow. One composite step, no Node, no Docker,
no third-party dependencies: just `curl` and the Bot API.

## Usage

```yaml
- uses: kevinnan94/telegram-notify-action@v1.0.1
  with:
    token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
    message: |
      <b>${{ github.repository }}</b> deploy finished
      Commit: <code>${{ github.sha }}</code>
      <a href="${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}">Run log</a>
```

Notify only on failure:

```yaml
- if: failure()
  uses: kevinnan94/telegram-notify-action@v1.0.1
  with:
    token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
    message: "❌ <b>${{ github.workflow }}</b> failed on ${{ github.ref_name }}"
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `token` | yes | | Bot token from @BotFather. Store it as a secret. |
| `chat_id` | yes | | User, group or channel id. Get yours from @userinfobot. |
| `message` | yes | | Text. HTML tags `<b>`, `<i>`, `<code>`, `<a>` are supported. |
| `parse_mode` | no | `HTML` | `HTML` or `MarkdownV2`. |
| `disable_preview` | no | `true` | Disable link previews. |

## Outputs

| Output | Description |
|---|---|
| `message_id` | Id of the message that was sent. |

## Behaviour

- Messages longer than 4096 characters are truncated (Telegram's limit).
- Text is JSON-escaped, so quotes, ampersands and newlines are safe.
- The token never appears in logs: errors print the API response only.

## Development

```bash
bash test/test_notify.sh
```

## License

MIT
