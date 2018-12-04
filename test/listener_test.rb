require_relative 'test_helper'

class ListenerTest < Minitest::Test

  def setup
    @amqp_config = {user: 'guest', password: 'guest'}
    @connector = AmqpHelper::Connector.new(:test, @amqp_config)
    @queue = 'amqp_helper_listener_test'
    @listener_name = 'listener'
  end

  def teardown
    AmqpHelper::Connector.clear_all_queues
  end

  def test_listener_creation
    listener = AmqpHelper::Listener.new(amqp_config: @amqp_config, queue_name: @queue,
                                        name: @listener_name, action_callback: -> { })
    assert_equal listener, AmqpHelper::Listener[@listener_name]
    refute AmqpHelper::Listener['some_other_name']
  end

  def test_listener_action
    @test_var = nil
    listener = AmqpHelper::Listener.new(amqp_config: @amqp_config, queue_name: @queue,
                                        name: @listener_name, action_callback: ->(payload) { @test_var = payload})
    Thread.new do
      listener.listen
    end
    assert_nil @test_var
    @connector.send_message(@queue, 'some_payload')
    sleep 0.1
    assert_equal 'some_payload', @test_var
  end

end