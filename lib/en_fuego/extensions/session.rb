module EnFuego
  module Extensions
    module Session
      def self.registered(app)
        app.helpers Helper
      end

      module Helper
        def session
          env['rack.session'].extend(Methods)
        end
      end

      module Methods
        def user
          if key?(:user)
            ::EnFuego::User[fetch(:user)]
          else
            nil
          end
        end

        def user=(user)
          if user
            store(:user, user.id)
          else
            delete(:user)
          end
        end
      end
    end
  end
end
