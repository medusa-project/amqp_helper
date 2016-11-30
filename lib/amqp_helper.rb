require 'amqp_helper/version'

module AmqpHelper
  autoload(:Listener, 'amqp_helper/listener')
  autoload(:Connector, 'amqp_helper/connector')
end
