#!/usr/bin/env ruby
# Standalone test script for email service with OpenTelemetry

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-exporter-otlp'
  gem 'opentelemetry-metrics-sdk'
  gem 'opentelemetry-exporter-otlp-metrics'
  gem 'opentelemetry-logs-sdk'
  gem 'opentelemetry-exporter-otlp-logs'
end

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry-metrics-sdk'
require 'opentelemetry-exporter-otlp-metrics'
require 'opentelemetry-logs-sdk'
require 'opentelemetry-exporter-otlp-logs'

# Configure OpenTelemetry SDK
OpenTelemetry::SDK.configure do |c|
  c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "email-test")
end

# Configure Metrics
otlp_metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
OpenTelemetry.meter_provider.add_metric_reader(otlp_metric_exporter)

# Global meter for application metrics
OTEL_METER = OpenTelemetry.meter_provider.meter("email-test")

# Global logger for application logs
OTEL_LOGGER = OpenTelemetry.logger_provider.logger(name: "email-test")

# Global tracer
OTEL_TRACER = OpenTelemetry.tracer_provider.tracer("email-test")

# Mock User class for testing
User = Struct.new(:id, :email, :display_name, keyword_init: true)

# Simplified Email Service Test
class EmailServiceTest
  class << self
    def confirmation_counter
      @confirmation_counter ||= OTEL_METER.create_counter(
        "app.email.confirmation.counter",
        unit: "1",
        description: "Counts the number of confirmation emails sent"
      )
    end

    def send_test_email(user)
      OTEL_TRACER.in_span("send_signup_confirmation") do |span|
        # Add attributes to the span
        span.add_attributes({
          "app.user.id" => user.id,
          "app.user.email" => user.email,
          "app.email.type" => "signup_confirmation"
        })

        puts "\n📧 EMAIL SERVICE TEST"
        puts "=" * 50

        begin
          # Simulate email delivery
          OTEL_TRACER.in_span("deliver_email") do |delivery_span|
            delivery_span.set_attribute("app.email.recipient", user.email)

            # Simulate email sending
            puts "📨 Sending email to: #{user.email}"
            puts "👤 User: #{user.display_name} (ID: #{user.id})"
            puts "✉️  Email Type: signup_confirmation"

            # Simulate email delivery delay
            sleep(0.5)

            puts "✅ Email sent successfully!"

            # Increment the counter metric
            confirmation_counter.add(1, attributes: {
              "app.email.type" => "signup_confirmation"
            })

            # Log the successful email send
            log_email_sent(user.email, "signup_confirmation", "SUCCESS")

            delivery_span.set_attribute("app.email.status", "sent")
          end

          span.set_attribute("app.email.result", "success")

          puts "\n📊 OPENTELEMETRY INSTRUMENTATION"
          puts "=" * 50
          puts "✓ Trace created: send_signup_confirmation"
          puts "✓ Span created: deliver_email"
          puts "✓ Metric incremented: app.email.confirmation.counter"
          puts "✓ Log emitted: Email sent successfully"
          puts "=" * 50

          { success: true, message: "Email sent successfully" }
        rescue StandardError => e
          # Add error information to span
          span.record_exception(e)
          span.set_attribute("app.email.result", "error")
          span.set_attribute("app.email.error", e.message)

          # Log the error
          log_email_error(user.email, "signup_confirmation", e.message)

          { success: false, message: e.message }
        end
      end
    end

    private

    def log_email_sent(recipient, email_type, status)
      OTEL_LOGGER.on_emit(
        timestamp: Time.now,
        severity_text: "INFO",
        body: "Email sent successfully",
        attributes: {
          "app.email.recipient" => recipient,
          "app.email.type" => email_type,
          "app.email.status" => status
        }
      )
    end

    def log_email_error(recipient, email_type, error_message)
      OTEL_LOGGER.on_emit(
        timestamp: Time.now,
        severity_text: "ERROR",
        body: "Failed to send email",
        attributes: {
          "app.email.recipient" => recipient,
          "app.email.type" => email_type,
          "app.email.error" => error_message
        }
      )
    end
  end
end

# Run the test
puts "\n🚀 Starting Email Service Test with OpenTelemetry"
puts "=" * 50

test_user = User.new(
  id: 1,
  email: "test@buildboard.com",
  display_name: "Test User"
)

result = EmailServiceTest.send_test_email(test_user)

puts "\n📋 TEST RESULT"
puts "=" * 50
if result[:success]
  puts "✅ Test passed: #{result[:message]}"
else
  puts "❌ Test failed: #{result[:message]}"
end

puts "\n💡 NOTE: In production, this would send an actual email."
puts "📝 OpenTelemetry data is being sent to: #{ENV.fetch('OTEL_EXPORTER_OTLP_ENDPOINT', 'http://localhost:4318')}"
puts "\nTo view traces, metrics, and logs, set up an OpenTelemetry backend like Jaeger."
puts "See EMAIL_SETUP.md for details."
puts "=" * 50