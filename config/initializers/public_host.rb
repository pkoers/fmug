public_app_url = ENV["APP_URL"].presence

if public_app_url
  uri = URI.parse(public_app_url[%r{\Ahttps?://}] ? public_app_url : "https://#{public_app_url}")
  default_url_options = {
    host: uri.host,
    protocol: "#{uri.scheme}://"
  }

  default_url_options[:port] = uri.port unless [ 80, 443 ].include?(uri.port)

  Rails.application.routes.default_url_options.merge!(default_url_options)
  Rails.application.config.action_mailer.default_url_options = default_url_options

  app_path = uri.path.to_s.sub(%r{/*\z}, "")
  base_host = "#{uri.scheme}://#{uri.host}"
  base_host = "#{base_host}:#{uri.port}" if default_url_options[:port]

  OmniAuth.config.full_host = lambda do |env|
    script_name = env["SCRIPT_NAME"].to_s
    "#{base_host}#{app_path}#{script_name}"
  end
end
