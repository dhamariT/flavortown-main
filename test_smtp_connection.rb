#!/usr/bin/env ruby
# Test SMTP connection without starting Rails

require 'net/smtp'
require 'dotenv/load'

puts "\n🔌 SMTP Connection Test"
puts "=" * 50

# Check if SMTP is configured
unless ENV['SMTP_ADDRESS']
  puts "❌ SMTP not configured!"
  puts "\nTo send real emails, add to your .env file:"
  puts <<~CONFIG
    SMTP_ADDRESS=smtp.gmail.com
    SMTP_PORT=587
    SMTP_USERNAME=your-email@gmail.com
    SMTP_PASSWORD=your-app-password
    MAILER_FROM_EMAIL=your-email@gmail.com
  CONFIG
  puts "\nSee SEND_REAL_EMAILS.md for detailed instructions."
  exit 1
end

# Display configuration
puts "Configuration:"
puts "  Address:  #{ENV['SMTP_ADDRESS']}"
puts "  Port:     #{ENV.fetch('SMTP_PORT', '587')}"
puts "  Username: #{ENV['SMTP_USERNAME']}"
puts "  Domain:   #{ENV['SMTP_DOMAIN'] || 'Not set'}"
puts "  From:     #{ENV['MAILER_FROM_EMAIL']}"
puts ""

# Test connection
begin
  puts "Testing SMTP connection..."

  smtp = Net::SMTP.new(
    ENV['SMTP_ADDRESS'],
    ENV.fetch('SMTP_PORT', 587).to_i
  )

  # Enable TLS if configured
  if ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', 'true') == 'true'
    smtp.enable_starttls_auto
  end

  # Try to connect and authenticate
  smtp.start(
    ENV['SMTP_DOMAIN'] || ENV['SMTP_ADDRESS'],
    ENV['SMTP_USERNAME'],
    ENV['SMTP_PASSWORD'],
    ENV.fetch('SMTP_AUTHENTICATION', 'plain')
  ) do |smtp_connection|
    puts "✅ SMTP connection successful!"
    puts "\n✨ Your email configuration is working!"
    puts "\nYou can now:"
    puts "  1. Restart your server: bin/dev"
    puts "  2. Test email endpoint:"
    puts "     curl -X POST http://localhost:3000/emails/test \\"
    puts "       -H 'Content-Type: application/json' \\"
    puts "       -d '{\"email\": \"#{ENV['SMTP_USERNAME']}\"}'"
  end

rescue Net::SMTPAuthenticationError => e
  puts "❌ Authentication failed!"
  puts "\nError: #{e.message}"
  puts "\nPossible issues:"
  puts "  • Wrong username or password"
  puts "  • For Gmail: Make sure you're using an App Password, not your regular password"
  puts "  • For SendGrid: Username should be 'apikey'"
  puts "\nDouble-check your credentials in .env file"
  exit 1

rescue SocketError => e
  puts "❌ Could not connect to SMTP server!"
  puts "\nError: #{e.message}"
  puts "\nPossible issues:"
  puts "  • Wrong SMTP address"
  puts "  • No internet connection"
  puts "  • Firewall blocking connection"
  exit 1

rescue => e
  puts "❌ Connection failed!"
  puts "\nError: #{e.class} - #{e.message}"
  puts "\nCheck your SMTP configuration in .env file"
  exit 1
end

puts "=" * 50