#!/usr/bin/env python3
import os
import re
import sys
import html
import smtplib
import argparse
from email.message import EmailMessage
from email.utils import make_msgid

URL_RE = re.compile(r"https?://[^\s<>\"]+")

FORMAT_TAG_RE = re.compile(r"</?[bu]>")
ESCAPED_FORMAT_TAG_RE = re.compile(r"&lt;(/?[bu])&gt;")

def body_to_plain(body):
    return FORMAT_TAG_RE.sub("", body)

def body_to_html(body):
    escaped = ESCAPED_FORMAT_TAG_RE.sub(r"<\1>", html.escape(body, quote=False))
    linked = URL_RE.sub(lambda m: f'<a href="{m.group(0)}">{m.group(0)}</a>', escaped)
    return ('<html><body><pre style="font-family: monospace; white-space: pre-wrap;">'
            f"{linked}</pre></body></html>\n")

def main():
    # 1. Setup Argument Parser
    parser = argparse.ArgumentParser(description="Secure CLI Email Wrapper",
                                     epilog="example: echo \"Ehlo!\" | ./emailer.py -s \"Hello World\" -f \"world.png\"")
    parser.add_argument("-s", "--subject", required=True, help="Email subject line")
    parser.add_argument("-f", "--file", help="Path to file to attach")
    parser.add_argument("-t", "--to", action="append", help="Recipient email(s) (defaults to SENDER_EMAIL env var)")
    parser.add_argument("--in-reply-to", help="Message-ID (from a prior run's printed 'Message-ID: <...>' line) "
                                               "to thread this email under - sets both the In-Reply-To and "
                                               "References headers to it.")
    parser.add_argument("--html", action="store_true",
                        help="Also send an HTML alternative of the body: monospace preformatted text "
                             "with http(s) URLs as clickable links, <b>...</b> shown bold and <u>...</u> "
                             "underlined. <b> and <u> tags are always stripped from the plain-text part.")
    args = parser.parse_args()

    # 2. Load Credentials from Environment (Security Best Practice)
    sender_email = os.environ.get("SENDER_EMAIL")
    app_password = os.environ.get("APP_PASSWORD")
    smtp_server = os.environ.get("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))

    if not sender_email or not app_password:
        print("Error: SENDER_EMAIL and APP_PASSWORD environment variables must be set.", file=sys.stderr)
        sys.exit(1)

    # Determine recipient: use argument or fallback to sender (sending to self)
    if args.to:
        recipients = [sender_email]
        for item in args.to:
            recipients.extend(
                addr.strip()
                for addr in item.split(",")
                if addr.strip()
            )
    else:
        recipients = [sender_email]
    
    # 3. Read Body from Standard Input (allows piping: echo "msg" | script.py)
    body = sys.stdin.read()
    if not body.strip():
        print("Error: No message body provided via stdin.", file=sys.stderr)
        sys.exit(1)

    # 4A. Construct Message
    subject = args.subject
    if args.in_reply_to and not subject.lower().startswith("re:"):
        subject = f"Re: {subject}"

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = sender_email
    msg["To"] = recipients
    msg["Message-ID"] = make_msgid()
    if args.in_reply_to:
        msg["In-Reply-To"] = args.in_reply_to
        msg["References"] = args.in_reply_to
    msg.set_content(body_to_plain(body))
    if args.html:
        msg.add_alternative(body_to_html(body), subtype="html")

    # 4B. Handle Attachment
    if args.file:
        if not os.path.exists(args.file):
            print(f"Error: File '{args.file}' not found.", file=sys.stderr)
            sys.exit(1)

        # Guess file type and add attachment
        try:
            with open(args.file, "rb") as f:
                file_data = f.read()
                file_name = os.path.basename(args.file)

            # add_attachment automatically guesses MIME type for common extensions
            msg.add_attachment(file_data,
                               maintype="application",
                               subtype="octet-stream",
                               filename=file_name)
            print(f"Attached: {file_name}")
        except Exception as e:
            print(f"Failed to attach file: {e}", file=sys.stderr)
            sys.exit(1)

    # 5. Send via SMTP with TLS
    try:
        with smtplib.SMTP(smtp_server, smtp_port, timeout=10) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(sender_email, app_password)
            server.send_message(msg)
        print(f"Email sent successfully to {recipients}.")
        print(f"Message-ID: {msg['Message-ID']}")
    except Exception as e:
        print(f"Failed to send email: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()   
