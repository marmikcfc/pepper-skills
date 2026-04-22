---
name: gmail
description: Send, read, and manage emails via Gmail. Use when asked to send an email, check inbox, read messages, draft emails, or manage Gmail.
---

# Gmail

Send, read, and manage emails through Gmail integration. Connect to your Gmail account via Composio to send emails, check your inbox, read messages, create drafts, and more.

## Requirements

- Gmail connected via Composio — connect at Settings → Integrations in Pepper Cloud dashboard (via Composio)
- OAuth connection must be active

## Credentials Check

```bash
# Verify Gmail is connected before proceeding
composio-tool apps | grep -i gmail || echo "Gmail not connected — user must connect at Settings → Integrations"
```

## Actions

### Send Email

Search for the action slug, then send an email.

```bash
# Search first to find exact slug
composio-tool search "send email" --toolkit gmail --limit 3

# Execute with the slug from search results
composio-tool execute GMAIL_SEND_EMAIL '{
  "recipient_email": "user@example.com",
  "body": "Hello, this is a test email.",
  "subject": "Test Email"
}'
```

**Parameters:**
- `recipient_email` (required) - Primary recipient's email address
- `body` (required) - Email content/message
- `subject` - Email subject line
- `cc` - CC recipients (comma-separated emails)
- `bcc` - BCC recipients (comma-separated emails)
- `is_html` - Send as HTML format (true/false)
- `attachment` - File attachment path

### List Emails

Retrieve emails from your inbox or specific folders.

```bash
# Search first to find exact slug
composio-tool search "list emails" --toolkit gmail --limit 3

# Execute with the slug from search results
composio-tool execute GMAIL_LIST_EMAILS '{
  "query": "is:unread",
  "max_results": 10
}'
```

**Parameters:**
- `query` - Gmail search query (e.g., "is:unread", "from:user@example.com")
- `max_results` - Maximum number of emails to return
- `label_ids` - Specific Gmail label IDs to search

### Get Email

Retrieve a specific email by its message ID.

```bash
# Search first to find exact slug
composio-tool search "fetch email" --toolkit gmail --limit 3

# Execute with the slug from search results
composio-tool execute GMAIL_FETCH_EMAIL_BY_MESSAGE_ID '{
  "message_id": "MESSAGE_ID_HERE"
}'
```

**Parameters:**
- `message_id` (required) - Gmail message ID to retrieve

### Create Draft

Create a draft email for later sending.

```bash
# Search first to find exact slug
composio-tool search "create draft" --toolkit gmail --limit 3

# Execute with the slug from search results
composio-tool execute GMAIL_CREATE_EMAIL_DRAFT '{
  "recipient_email": "user@example.com",
  "body": "Draft email content",
  "subject": "Draft Subject"
}'
```

**Parameters:**
- `recipient_email` (required) - Primary recipient's email address
- `body` (required) - Email content/message
- `subject` (required) - Email subject line
- `cc` - CC recipients (comma-separated emails)
- `bcc` - BCC recipients (comma-separated emails)
- `is_html` - Draft as HTML format (true/false)

### Search Emails

Search emails using Gmail search syntax.

```bash
# Search first to find exact slug
composio-tool search "search emails" --toolkit gmail --limit 3

# Execute with the slug from search results
composio-tool execute GMAIL_LIST_EMAILS '{
  "query": "from:customers subject:feedback",
  "max_results": 50
}'
```

## Usage Examples

**Send a quick email:**
```bash
composio-tool search "send email" --toolkit gmail --limit 3
composio-tool execute GMAIL_SEND_EMAIL '{"recipient_email":"colleague@company.com","body":"The report is ready for review.","subject":"Report Ready"}'
```

**Check unread emails:**
```bash
composio-tool search "list emails" --toolkit gmail --limit 3
composio-tool execute GMAIL_LIST_EMAILS '{"query":"is:unread","max_results":5}'
```

**Get a specific email:**
```bash
composio-tool search "fetch email" --toolkit gmail --limit 3
composio-tool execute GMAIL_FETCH_EMAIL_BY_MESSAGE_ID '{"message_id":"17a1b2c3d4e5f6g7"}'
```

**Create an HTML draft:**
```bash
composio-tool search "create draft" --toolkit gmail --limit 3
composio-tool execute GMAIL_CREATE_EMAIL_DRAFT '{"recipient_email":"team@company.com","subject":"Weekly Update","body":"<h1>Weekly Report</h1><p>All tasks completed.</p>","is_html":true}'
```

## Error Handling

- **Gmail not connected** - Run `composio-tool apps | grep -i gmail` to check. Connect at Settings → Integrations in Pepper Cloud dashboard (via Composio)
- **400 Bad Request** - Invalid email format or missing required parameters
- **403 Forbidden** - Insufficient permissions or quota exceeded
- **404 Not Found** - Message ID does not exist
- **429 Rate Limited** - Too many requests, wait before retrying

## Tips

- Always run `composio-tool search` before `composio-tool execute` — slugs are unpredictable and may differ from examples above
- Use Gmail search syntax in `query` parameter (is:unread, from:email, has:attachment)
- Set `max_results` appropriately to avoid large responses
- HTML emails need `is_html=true` parameter
- Draft emails can be edited later in Gmail interface
