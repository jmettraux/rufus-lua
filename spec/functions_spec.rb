
#
# Specifying rufus-lua
#
# Wed Mar 11 17:09:17 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  describe 'Lua functions' do

    before do
      @s = Rufus::Lua::State.new
    end
    after do
      @s.close
    end

    it 'are returned as Rufus::Lua::Function instances' do

      expect(@s.eval('return function () end').class).to eq Rufus::Lua::Function
    end

    it 'are callable from Ruby' do

      f = @s.eval(%{
        f = function ()
          return 77
        end
        return f
      })

      expect(f.call()).to eq 77.0
    end

    it 'are callable even when they return multiple values' do

      f = @s.eval(%{
        f = function ()
          return 77, 44
        end
        return f
      })

      expect(f.call()).to eq [ 77.0, 44.0 ]
    end

    it 'are callable with arguments' do

      f = @s.eval(%{
        f = function (x)
          return x * x
        end
        return f
      })

      expect(f.call(2)).to eq 4.0
    end

    it 'are callable with boolean arguments' do

      f = @s.eval(%{
        f = function (x)
          return x
        end
        return f
      })

      expect(f.call(true)).to eq true
      expect(f.call(false)).to eq false
    end

    it 'are callable with array arguments' do

      f = @s.eval(%{
        f = function (x)
          return x
        end
        return f
      })

      expect(f.call(%w[ one two three ]).to_a).to eq %w[ one two three ]
    end

    it 'are callable with multiple arguments' do

      f = @s.eval(%{
        f = function (x, y)
          return x + y
        end
        return f
      })

      expect(f.call(1, 2)).to eq 3.0
    end

    it 'are called with #to_lua\'ed Ruby arguments' do

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

      expect(f.call(t)).to eq t.to_lua
    end
  end
end

