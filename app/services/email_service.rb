# Service for sending emails with OpenTelemetry instrumentation
class EmailService
  class << self
    # Initialize metrics counter
    def confirmation_counter
      @confirmation_counter ||= OTEL_METER.create_counter(
        "app.email.confirmation.counter",
        unit: "1",
        description: "Counts the number of confirmation emails sent"
      )
    end

    # Send a signup confirmation email with full OpenTelemetry instrumentation
    def send_signup_confirmation(user)
      OTEL_TRACER.in_span("send_signup_confirmation") do |span|
        # Add attributes to the span
        span.add_attributes({
          "app.user.id" => user.id,
          "app.user.email" => user.email,
          "app.email.type" => "signup_confirmation"
        })

        begin
          # Send the actual email
          OTEL_TRACER.in_span("deliver_email") do |delivery_span|
            delivery_span.set_attribute("app.email.recipient", user.email)

            # Call the mailer
            UserMailer.signup_confirmation(user).deliver_now

            # Increment the counter metric
            confirmation_counter.add(1, attributes: {
              "app.email.type" => "signup_confirmation"
            })

            # Log the successful email send
            log_email_sent(user.email, "signup_confirmation", "SUCCESS")

            delivery_span.set_attribute("app.email.status", "sent")
          end

          span.set_attribute("app.email.result", "success")
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

    # Send a test email
    def send_test_email(email, subject = "Test Email")
      OTEL_TRACER.in_span("send_test_email") do |span|
        span.add_attributes({
          "app.email.recipient" => email,
          "app.email.type" => "test",
          "app.email.subject" => subject
        })

        begin
          UserMailer.test_email(email, subject).deliver_now

          # Increment counter
          confirmation_counter.add(1, attributes: {
            "app.email.type" => "test"
          })

          # Log success
          log_email_sent(email, "test", "SUCCESS")

          span.set_attribute("app.email.result", "success")
          { success: true, message: "Test email sent successfully" }
        rescue StandardError => e
          span.record_exception(e)
          span.set_attribute("app.email.result", "error")

          log_email_error(email, "test", e.message)

          { success: false, message: e.message }
        end
      end
    end

    private

    # Log email sent event
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

    # Log email error
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