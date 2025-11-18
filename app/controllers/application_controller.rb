class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # Add Policy Pundit
  include Pundit::Authorization

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  private

  def user_not_authorized
    flash[:alert] = "You must be logged in to access this page"
    redirect_to root_path
  end
end