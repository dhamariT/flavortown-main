#!/bin/bash

echo "🔐 Setting up SSL certificates for local development"
echo "=================================================="

# Generate self-signed SSL certificate
if [ ! -f localhost.key ] || [ ! -f localhost.crt ]; then
    echo "📜 Generating self-signed SSL certificate..."

    openssl req -x509 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -days 365 -nodes \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,DNS:0.0.0.0,IP:127.0.0.1"

    echo "✅ SSL certificate created!"
    echo "   - localhost.key"
    echo "   - localhost.crt"
else
    echo "✅ SSL certificates already exist"
fi

echo ""
echo "=================================================="
echo "SSL certificates are ready!"
echo ""
echo "Next steps:"
echo "1. Trust the certificate in your browser:"
echo "   - Open https://localhost:3000 in your browser"
echo "   - Accept the security warning (it's safe, it's your own cert)"
echo ""
echo "2. Update your Slack app OAuth redirect URLs:"
echo "   - Go to https://api.slack.com/apps"
echo "   - Add these URLs to OAuth & Permissions:"
echo "     • https://localhost:3000/auth/slack/callback"
echo "     • https://0.0.0.0:3000/auth/slack/callback"
echo ""