#Represent AMQP connection and provide convenience methods.
#The amqp section of Settings.medusa can contain any option appropriate for Bunny.new.
require 'set'
require 'json'
require 'bunny'
require 'bunny-mock'

BunnyMock::use_bunny_queue_pop_api = true

module AmqpHelper
  class Connector < Object

    attr_accessor :known_queues, :config

    def initialize(key, config)
      self.class.connectors ||= Hash.new
      self.class.connectors[key] = self
      config_hash = config.to_h
      config_hash = config_hash.symbolize_keys if config_hash.respond_to?(:symbolize_keys)
      self.config = config_hash.merge!(recover_from_connection_close: true)
      @connection = nil
      self.reinitialize
    end

    def self.connectors
      @connectors
    end

    def self.connectors=(object)
      @connectors = object
    end

    def connection=(conn)
      @connection = conn
    end

    def connection(ensure_started: true)
      ensure_connection_started if ensure_started
      @connection
    end

    def ensure_connection_started
      unless @connection.open?
        @connection.start
        while @connection.connecting?
          sleep 0.01
        end
      end
    end
    
    def self.connector(key)
      self.connectors[key]
    end

    def self.[](key)
      self.connector(key)
    end

    def reinitialize
      self.known_queues = Set.new
      self.connection.close if self.connection(ensure_started: false)
      self.connection = Bunny.new(self.config)
    end

    def self.clear_all_queues
      self.connectors.values.each { |connector| connector.clear_all_queues } if self.connectors
    end

    def clear_all_queues
      self.clear_queues(*self.known_queues.to_a)
    end

    def clear_queues(*queue_names)
      queue_names.each do |queue_name|
        continue = true
        while continue
          with_message(queue_name) do |message|
            continue = message
            if message && self.config[:logger]
              self.config[:logger].debug("#{self.class} clearing: #{message} from: #{queue_name}")
            end
          end
        end
      end
    end

    def with_channel
      channel = connection.create_channel
      yield channel
    ensure
      channel.close if channel and channel.open?
    end

    def with_queue(queue_name)
      with_channel do |channel|
        queue = channel.queue(queue_name, durable: true)
        yield queue
      end
    end

    def ensure_queue(queue_name)
      unless self.known_queues.include?(queue_name)
        with_queue(queue_name) do |queue|
          #no-op, just ensuring queue exists
        end
        self.known_queues << queue_name
      end
    end

    def with_message(queue_name)
      with_queue(queue_name) do |queue|
        delivery_info, properties, raw_payload = queue.pop
        yield raw_payload
      end
    end

    def with_parsed_message(queue_name)
      with_message(queue_name) do |message|
        json_message = message ? JSON.parse(message) : nil
        yield json_message
      end
    end

    def with_exchange
      with_channel do |channel|
        exchange = channel.default_exchange
        yield exchange
      end
    end

    def send_message(queue_name, message)
      ensure_queue(queue_name)
      with_exchange do |exchange|
        message = message.to_json if message.is_a?(Hash)
        exchange.publish(message, routing_key: queue_name, persistent: true)
      end
    end

    ### The following are for testing, if it is desired to mock.
    # We test the gem itself against a real rabbitmq, but clients using
    # this gem might decide they want to mock
    def self.mock_all
      self.connectors.values.each { |connector| connector.mock }
    end

    # effectively reinitialize with BunnyMock connection
    def mock
      self.known_queues = Set.new
      self.connection.close if self.connection(ensure_started: false)
      self.connection = BunnyMock.new(self.config).start
    end

  end
end
