#The amqp config is the connection config, including vhost
#queue name is the queue to take messages from
#name is just a string to refer to this listener, use in logs, etc. Must be unique
#action callback is a block that takes the payload received and does whatever to it
require 'bunny'
module AmqpHelper
  class Listener

    attr_accessor :amqp_config, :queue_name, :name, :action_callback, :connection, :logger, :consumer

    def initialize(amqp_config:, queue_name:, name:, action_callback:, logger: nil)
      self.amqp_config = if amqp_config
                           hash = amqp_config.to_h
                           hash = hash.symbolize_keys if hash.respond_to?(:symbolize_keys)
                           hash
                         else
                           Hash.new
                         end
      self.queue_name = queue_name
      self.name = name
      self.action_callback = action_callback
      self.class.listeners ||= Hash.new
      self.class.listeners[self.name] = self
      self.logger = if logger
                      logger
                    elsif defined? (Rails) and Rails.respond_to?(:logger)
                      Rails.logger
                    else
                      nil
                    end
      self.connect
    end

    def self.listeners
      @listeners
    end

    def self.listeners=(object)
      @listeners = object
    end

    def self.listener(key)
      self.listeners[key]
    end

    def self.[](key)
      self.listener(key)
    end

    def connect
      self.connection = Bunny.new(amqp_config)
      self.connection.start
      Kernel.at_exit do
        self.connection.close rescue nil
      end
    end

    def queue
      channel = connection.create_channel
      channel.queue(queue_name, durable: true)
    end

    def listen
      logger.info "Starting AMQP listener for #{name}" if logger
      self.consumer = queue.subscribe do |delivery_info, properties, payload|
        begin
          action_callback.call(payload)
        rescue Exception => e
          logger.error "Failed to handle #{name} repsonse #{payload}: #{e}" if logger
        end
      end
    rescue Exception => e
      logger.error "Unknown error starting AMQP listener for #{name}: #{e}" if logger
    end

    def unlisten
      self.consumer.cancel if self.consumer
      self.consumer = nil
    end

    def self.unlisten_all
      listeners.values.each(&:unlisten)
    end

  end
end