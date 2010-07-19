module EnFuego
  module Extensions

    # TOTALLY ganked from Ryan Tomayko's sinatra-sequel. I'd use his directly,
    # but the gem has an errant runtime dependency on bacon.
    module Sequel
      def database
        @database ||= ::Sequel.connect(database_url)
      end

      def migration(name, &block)
        create_migrations_table
        return if database[:migrations].filter(:name => name).count > 0
        database.transaction do
          yield database
          database[:migrations] << { :name => name, :ran_at => Time.now }
        end
      end

      protected

      def create_migrations_table
        database.create_table? :migrations do
          primary_key :id
          String :name, :null => false, :index => true
          timestamp :ran_at
        end
      end

      def self.registered(app)
        app.set :database_url, ENV['DATABASE_URL'] || 'sqlite::memory:'
      end
    end
  end
end
