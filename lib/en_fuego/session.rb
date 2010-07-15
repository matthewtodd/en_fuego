module EnFuego
  module Session
    def request_token(consumer)
      OAuth::RequestToken.from_hash(consumer, self)
    end

    def request_token=(request_token)
      self[:oauth_token]        = request_token.token
      self[:oauth_token_secret] = request_token.secret
    end

    def user
      User.find(self[:user])
    end

    def user=(user)
      self[:user] = user.to_key
    end
  end
end
