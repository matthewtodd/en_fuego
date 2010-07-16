module EnFuego
  module Extensions
    module OpenID

      def self.registered(app)
        app.use Rack::OpenID
        app.helpers Helper
      end

      module Helper
        def authenticate_with_openid
          if response = request.env[Rack::OpenID::RESPONSE]
            case response.status
            when :success
              yield response.identity_url
            end
          else
            headers Rack::OpenID::AUTHENTICATE_HEADER =>
              Rack::OpenID.build_header(:identifier => params['openid_url'])
            halt [401, 'You are being redirected.']
          end
        end
      end

    end
  end
end
