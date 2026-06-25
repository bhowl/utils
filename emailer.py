#!/usr/bin/env python3
import os
import sys
import smtplib
import argparse
from email.message import EmailMessage

def main():
    # 1. Setup Argument Parser
    parser = argparse.ArgumentParser(description="Secure CLI Email Wrapper",
                                     epilog="example: echo \"Ehlo!\" | ./emailer.py -s \"Hello World\" -f \"world.png\"")
    parser.add_argument("-s", "--subject", required=True, help="Email subject line")
    parser.add_argument("-f", "--file", help="Path to file to attach")
    parser.add_argument("-t", "--to", help="Recipient email (defaults to SENDER_EMAIL env var)")
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
    recipient = args.to if args.to else sender_email

    # 3. Read Body from Standard Input (allows piping: echo "msg" | script.py)
    body = sys.stdin.read()
    if not body.strip():
        print("Error: No message body provided via stdin.", file=sys.stderr)
        sys.exit(1)

    # 4A. Construct Message
    msg = EmailMessage()
    msg["Subject"] = args.subject
    msg["From"] = sender_email
    msg["To"] = recipient
    msg.set_content(body)

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
        print(f"Email sent successfully to {recipient}.")
    except Exception as e:
        print(f"Failed to send email: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()   
