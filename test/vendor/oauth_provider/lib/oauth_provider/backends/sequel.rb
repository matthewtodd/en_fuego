raise "Sequel backend is incomplete"

gem 'sequel'
require 'sequel'

module OAuthProvider
  module Backends
    class Sequel
      def initialize(uri)
        @db = Sequel.connect(uri)
      end

      def save_consumer(consumer)
        @db.execute("INSERT INTO consumers (name, shared, secret, callback) " \
                    "VALUES ('#{consumer.name}', '#{consumer.shared}', '#{consumer.secret}', '#{consumer.callback}')")
      end

      def fetch_consumer(shared)
        @db.execute("SELECT name, shared, secret, callback FROM consumers WHERE shared = '#{shared}' LIMIT 1") do |row|
          return Consumer.new(self, row[0], row[1], row[2], row[3])
        end
        nil
      end

      def save_request_token(token)
        @db.execute("INSERT INTO request_tokens (shared, secret, authorized, consumer_shared) " \
                    "VALUES ('#{token.shared}','#{token.secret}',#{token.authorized ? 1 : 0},'#{token.consumer_shared}')")
      end

      def fetch_request_token(shared, consumer_shared)
        consumer_shared = "AND consumer_shared='#{consumer_shared}'" if consumer_shared
        @db.execute("SELECT shared, secret, authorized, consumer_shared FROM request_tokens WHERE shared = '#{shared}' #{consumer_shared} LIMIT 1") do |row|
          consumer = fetch_consumer(row[3])
          return RequestToken.new(consumer, row[2], row[0], row[1])
        end
        nil
      end

      def authorize_request_token(token)
        @db.execute("UPDATE request_tokens SET authorized=1 WHERE shared='#{token.shared}'")
      end

      def save_access_token(token)
        @db.execute("INSERT INTO access_tokens (shared, secret, consumer_shared, request_shared) " \
                    "VALUES ('#{token.shared}','#{token.secret}','#{token.consumer_shared}', '#{token.request_shared}')")
      end

      def fetch_access_token(shared, consumer_shared)
        consumer_shared = "AND consumer_shared='#{consumer_shared}'" if consumer_shared
        @db.execute("SELECT shared, secret, request_shared, consumer_shared FROM access_tokens WHERE shared = '#{shared}' #{consumer_shared} LIMIT 1") do |row|
          consumer = fetch_consumer(row[3])
          return AccessToken.new(consumer, row[2], row[0], row[1])
        end
        nil
      end

      private

      def create_tables
        @db.execute("CREATE TABLE IF NOT EXISTS consumers (name CHAR(50), shared CHAR(32) PRIMARY KEY, secret CHAR(32), callback CHAR(255))")
        @db.execute("CREATE TABLE IF NOT EXISTS request_tokens (shared CHAR(16) PRIMARY KEY, secret CHAR(32), authorized INT, consumer_shared CHAR(32))")
        @db.execute("CREATE TABLE IF NOT EXISTS access_tokens (shared CHAR(16) PRIMARY KEY, secret CHAR(32), request_shared CHAR(32), consumer_shared CHAR(32))")
        unless @db.table_exists?(:consumers)
          @db.create_table :consumers do
            primary_key :id
            text :name, :shared, :secret, :callback, :unique => true, :null => false
            index :shared
          end
        end

        unless @db.table_exists?(:request_tokens)
          primary_key :id
          text :shared_key, :secret_key, :unique => true, :null => false
          foreign_key :consumer_id, :consumers
          index :shared_key, :consumer_id
          end
      end
    end
  end
end

