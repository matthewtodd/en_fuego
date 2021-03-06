module EnFuego
  module Extensions
    module OAuth

      attr_accessor :oauth_consumer

      def self.registered(app)
        app.helpers Helper
      end

      module Helper
        def oauth_consumer
          options.oauth_consumer
        end

        def start_authorize_with_oauth(user_attributes)
          request_token = oauth_consumer.get_request_token

          session[:oauth_token]        = request_token.token
          session[:oauth_token_secret] = request_token.secret
          session[:user_attributes]    = user_attributes

          redirect request_token.authorize_url
        end

        def finish_authorize_with_oauth
          user_attributes = session[:user_attributes] || {}

          with_access_token do |access_token|
            yield user_attributes.merge(
                    :oauth_token        => access_token.token,
                    :oauth_token_secret => access_token.secret
                  )
          end

          session.delete(:oauth_token)
          session.delete(:oauth_token_secret)
          session.delete(:user_attributes)
        end

        def with_access_token
          options = { :oauth_verifier => params[:oauth_verifier] }

          with_request_token do |request_token|
            yield request_token.get_access_token(options)
          end
        end

        def with_request_token
          if params[:oauth_token] == session[:oauth_token]
            yield ::OAuth::RequestToken.new(
                      oauth_consumer,
                      session[:oauth_token],
                      session[:oauth_token_secret]
                    )
          end
        end

      end

    end
  end
end

