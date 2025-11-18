class UserMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_FROM_EMAIL", "dhamari@hackclub.com")

  # Signup confirmation email
  def signup_confirmation(user)
    @user = user
    @login_url = root_url

    mail(
      to: user.email,
      subject: "Welcome to Buildboard! 🎉"
    )
  end

  # Test email for debugging
  def test_email(email, subject = "Test Email from Buildboard")
    @email = email
    @timestamp = Time.current

    mail(
      to: email,
      subject: subject
    )
  end
end