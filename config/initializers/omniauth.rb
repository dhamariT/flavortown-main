OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.on_failure = proc { |env|
  SessionsController.action(:failure).call(env)
}

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
    name: :slack,
    scope: [:openid, :profile, :email],
    response_type: :code,
    issuer: 'https://slack.com',
    discovery: true,
    client_options: {
      identifier: ENV["SLACK_CLIENT_ID"],
      secret: ENV["SLACK_CLIENT_SECRET"],
      redirect_uri: "https://localhost:3000/auth/slack/callback",
      host: 'slack.com',
      authorization_endpoint: 'https://slack.com/openid/connect/authorize',
      token_endpoint: 'https://slack.com/api/openid.connect.token',
      userinfo_endpoint: 'https://slack.com/api/openid.connect.userInfo'
    },
    state: proc { SecureRandom.hex(24) },
    nonce: proc { SecureRandom.hex(24) }
end