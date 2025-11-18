class EmailsController < ApplicationController
  # Skip CSRF verification for API endpoints
  skip_before_action :verify_authenticity_token

  # Test endpoint to send emails
  # POST /emails/test
  def test
    email = params[:email]

    if email.blank?
      render json: { error: "Email parameter is required" }, status: :bad_request
      return
    end

    # Validate email format
    unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      render json: { error: "Invalid email format" }, status: :bad_request
      return
    end

    result = EmailService.send_test_email(email, params[:subject])

    if result[:success]
      render json: {
        success: true,
        message: result[:message],
        email: email
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:message]
      }, status: :unprocessable_entity
    end
  end

  # Test endpoint for signup confirmation
  # POST /emails/test_signup
  def test_signup
    user_id = params[:user_id]

    if user_id.blank?
      render json: { error: "user_id parameter is required" }, status: :bad_request
      return
    end

    user = User.find_by(id: user_id)

    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    result = EmailService.send_signup_confirmation(user)

    if result[:success]
      render json: {
        success: true,
        message: result[:message],
        user: {
          id: user.id,
          email: user.email,
          display_name: user.display_name
        }
      }, status: :ok
    else
      render json: {
        success: false,
        error: result[:message]
      }, status: :unprocessable_entity
    end
  end
end