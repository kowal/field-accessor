# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'field_accessor'

class User
  extend FieldAccessor
  field_accessor :name
end

class FieldAccessorTest < Test::Unit::TestCase

  def setup
    @user = User.new
    @name = "john doe"
  end

  def test_not_initialized
    assert_nil @user.name    
  end

  def test_init_by_obj
    @user.name = @name    
    assert_equal(@name, @user.name)
  end

  def test_init_by_lambda
    may_change = "one"
    @user.name = lambda { may_change }

    assert_equal("one", @user.name)

    may_change = "two"
    assert_equal("two", @user.name)    
  end

  def test_init_by_bind
    @other = ["other", "model"]

    @user.bind(:name => @other) do
      read { target.last }
      write { |v| target.push(v) }
    end

    assert_equal(@other.last, @user.name)    

    @other.push("latest")
    assert_equal("latest", @user.name)

    @user.name = "even latest"
    assert_equal("even latest", @user.name)
    assert_equal("even latest", @other.last)    
  end

  def test_put_errors
    @other = ["ok", "ok2"]
    @user.bind(:name => @other) do
      read { target.last }
      write { |v| v[/ok/] ? target.push(v) : raise("Not valid") }
    end

    @user.name = "ok3" # valid
    assert_equal("ok3", @user.name)
    assert_equal("ok3", @other.last)

    @user.name = "error" # invalid
    assert_equal("error", @user.name)
    assert_equal("ok3", @other.last)

    @user.name = "ok4" # valid again
    assert_equal("ok4", @user.name)
    assert_equal("ok4", @other.last)
  end
end
