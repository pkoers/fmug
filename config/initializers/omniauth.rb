OmniAuth.config.allowed_request_methods = [ :post ]

google_client_id = ENV["GOOGLE_CLIENT_ID"]
google_client_secret = ENV["GOOGLE_CLIENT_SECRET"]

if google_client_id.present? && google_client_secret.present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
      google_client_id,
      google_client_secret,
      scope: "email,profile",
      prompt: "select_account"
  end
end
