
#
# Specifying rufus-lua
#
# Wed Mar 11 17:09:17 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State (functions)' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should return Lua functions' do
    @s.eval('return function () end').class.should.equal(Rufus::Lua::Function)
  end

  it 'should call Lua functions' do
    f = @s.eval(%{
      f = function ()
        return 77
      end
      return f
    })
    f.call().should.equal(77.0)
  end

  it 'should call Lua functions which return multiple values' do
    f = @s.eval(%{
      f = function ()
        return 77, 44
      end
      return f
    })
    f.call().should.equal([ 77.0, 44.0 ])
  end

  it 'should call functions with arguments' do
    f = @s.eval(%{
      f = function (x)
        return x * x
      end
      return f
    })
    f.call(2).should.equal(4.0)
  end

  it 'should call functions with boolean arguments' do
    f = @s.eval(%{
      f = function (x)
        return x
      end
      return f
    })
    f.call(true).should.equal(true)
    f.call(false).should.equal(false)
  end

  it 'should call functions with an array argument' do
    f = @s.eval(%{
      f = function (x)
        return x
      end
      return f
    })
    f.call(%w[ one two three ]).to_a.should.equal(%w[ one two three ])
  end

  it 'should call functions with multiple arguments' do
    f = @s.eval(%{
      f = function (x, y)
        return x + y
      end
      return f
    })
    f.call(1, 2).should.equal(3.0)
  end

  it 'should call honour the to_lua method for ruby args' do

    f = @s.eval(%{
      f = function (x)
        return x
      end
      return f
    })

    t = Time.now

    def t.to_lua
      "lua:#{to_s}"
    end

    f.call(t).should.equal(t.to_lua)
  end
end

