Rails.application.config.session_store :cookie_store,
  key: '_flavortown_session',
  secure: false, # Allow session cookies over HTTPS localhost
  same_site: :lax,
  httponly: true