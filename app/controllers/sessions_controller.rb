class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    Rails.logger.info "🔐 SessionsController#create called - Request ID: #{request.request_id}"
    Rails.logger.info "   Path: #{request.path}, Method: #{request.method}"
    
    auth = request.env["omniauth.auth"]
    
    unless auth
      Rails.logger.error "❌ No auth data in omniauth.auth"
      redirect_to root_path, alert: "Authentication failed - no auth data"
      return
    end
    
    provider = auth.provider
    
    # Debug: Log the entire auth structure to find where uid is
    Rails.logger.info "🔍 Full auth structure:"
    Rails.logger.info "   provider: #{auth.provider}"
    Rails.logger.info "   uid: #{auth.uid.inspect}"
    Rails.logger.info "   info: #{auth.info.to_hash.inspect}"
    Rails.logger.info "   credentials: #{auth.credentials.to_hash.inspect}"
    Rails.logger.info "   extra: #{auth.extra.to_hash.inspect}" if auth.respond_to?(:extra)
    
    uid = auth.uid || auth.dig('extra', 'raw_info', 'sub') || auth.dig('extra', 'user_id')
    info = auth.info
    cred = auth.credentials

    Rails.logger.info "🔐 OAuth callback processing: provider=#{provider}, uid=#{uid}"
    
    if uid.blank?
      Rails.logger.error "❌ UID is blank! Cannot proceed with authentication."
      redirect_to root_path, alert: "Authentication failed - no user ID received from Slack"
      return
    end

    # provider is a symbol. do not change it to string... equality will fail otherwise

    if provider.to_sym == :slack
      identity = User::Identity.find_or_initialize_by(provider: provider, uid: uid)

      identity.access_token = cred.token
      identity.refresh_token = cred.refresh_token if cred.refresh_token.present?

      user = identity.user
      is_new_user = user.nil?

      unless user
        # info.name is overwritten once the callback runs. We're setting something for now...
        user = User.create!(display_name: info.name, email: info.email)
      end

      identity.user = user
      identity.save!

      # Send signup confirmation email for new users
      if is_new_user
        EmailService.send_signup_confirmation(user)
      end

      # Set session
      session[:user_id] = user.id
      session[:logged_out] = false  # Clear logged_out flag

      Rails.logger.info "✅ User ##{user.id} authenticated via Slack. Redirecting to projects_path"
      redirect_to projects_path, notice: "Signed in with Slack"
    else
      redirect_to root_path, alert: "Authentication failed or user already signed in"
    end
  end

  def destroy
    session[:logged_out] = true
    session[:user_id] = nil
    redirect_to root_path, notice: "Signed out"
  end

  def failure
    error_type = request.env['omniauth.error.type']
    error_msg = params[:message] || request.env['omniauth.error']&.message || "Unknown error"
    
    Rails.logger.error "❌ OAuth failure: #{error_type} - #{error_msg}"
    
    # Handle specific error cases
    if error_msg.include?("code_already_used") || error_type.to_s.include?("OAuth2::Error")
      redirect_to root_path, alert: "Authentication session expired. Please try signing in again."
    else
      redirect_to root_path, alert: "Authentication failed: #{error_msg}"
    end
  end
end