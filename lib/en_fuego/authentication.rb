module EnFuego
  module Authentication

    class OAuth < Warden::Strategies::Base
      def authenticate!
        if params.include?('oauth_token')
          request_token = DailyMile.load_request_token(session).extend(RequestTokenExtensions)

          if request_token.blank?
            fail!('There is no OAuth authentication in progress.')
          elsif request_token.differs?(params['oauth_token'])
            fail!("Received OAuth token didn't match stored OAuth token.")
          else
            request_token.forget(session)
            access_token = request_token.get_access_token(:oauth_verifier => params['oauth_verifier'])
            user =   User.find_by_oauth_token(access_token.token)
            user ||= User.create(:oauth_token => access_token.token, :oath_token_secret => access_token.secret)
            success!(user)
          end
        else
          request_token = DailyMile.get_request_token.extend(RequestTokenExtensions)
          request_token.store(session)
          redirect!(request_token.authorize_url)
          throw(:warden)
        end
      end

      private

      module RequestTokenExtensions
        def blank?
          token.nil?
        end

        def differs?(token)
          self.token != token
        end

        def forget(session)
          params.each_key { |key| session.delete(key) }
        end

        def store(session)
          params.each { |key, value| session[key] = value }
        end
      end
    end

  end
end
