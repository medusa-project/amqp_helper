require_relative 'test_helper'

class AmqpHelperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AmqpHelper::VERSION
  end

  def test_it_does_something_useful
    assert true
  end
end
