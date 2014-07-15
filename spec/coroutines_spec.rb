
#
# Specifying rufus-lua
#
# Sat Mar 14 23:51:42 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  describe 'a Lua coroutine' do

    before do
      @s = Rufus::Lua::State.new
    end
    after do
      @s.close
    end

    it 'can be returned to Ruby' do

      expect(@s.eval(
        'return coroutine.create(function (x) end)'
      ).class).to eq(Rufus::Lua::Coroutine)
    end

    it 'has a status visible from Ruby' do

      co = @s.eval(
        'return coroutine.create(function (x) end)'
      )
      expect(co.status).to eq('suspended')
    end

    it 'can be resumed from Ruby' do

      @s.eval(%{
        co = coroutine.create(function (x)
          while true do
            coroutine.yield(x)
          end
        end)
      })
      expect(@s['co'].resume(7)).to eq [ true, 7.0 ]
      expect(@s['co'].resume()).to eq [ true, 7.0 ]
    end

    it 'can be resumed from Ruby (and is not averse to \0 bytes)' do

      @s.eval(%{
        co = coroutine.create(function (x)
          while true do
            coroutine.yield(x)
          end
        end)
      })
      s = [ 0, 64, 0, 0, 65, 0 ].pack('c*')
      expect(@s['co'].resume(s)).to eq [ true, s ]
      expect(@s['co'].resume()).to eq [ true, s ]
    end

    # compressed version of the spec proposed by Nathanael Jones
    # in https://github.com/nathanaeljones/rufus-lua/commit/179184aS
    #
    # for https://github.com/jmettraux/rufus-lua/issues/19
    #
    it 'yields the right value' do

      pending 'yield across callback no worky on Lua 5.1.x'

      @s.function :host_function do
        'success'
      end
      r = @s.eval(%{
        function routine()
          coroutine.yield(host_function())
          --coroutine.yield("success") -- that works :-(
        end
        co = coroutine.create(routine)
        a, b = coroutine.resume(co)
        return { a, b }
      }).to_ruby

      expect(r).to eq([ true, 'success' ])
    end


    it 'executes a ruby function within a coroutine' do

      run_count = 0

      @s.function :host_function do
        run_count += 1
      end
      r = @s.eval(%{
        function routine()
          host_function()
          coroutine.yield()
          host_function()
          coroutine.yield()
        end
        co = coroutine.create(routine)
        a, b = coroutine.resume(co)
        a, b = coroutine.resume(co)
        return { a, b }
      }).to_ruby

      expect(r).to eq([ true])
      expect(run_count).to eq(2)
    end

    it 'executes a ruby function (with arguments) within a coroutine' do

      run_count = 0
      last_argument = nil

      @s.function :host_function do |arg|
        run_count += 1
        last_argument = arg
      end
      r = @s.eval(%{
        function routine()
          host_function("hi")
          coroutine.yield()
        end
        co = coroutine.create(routine)
        a, b = coroutine.resume(co)
        return { a, b }
      }).to_ruby

      expect(r).to eq([ true])
      expect(run_count).to eq(1)
      expect(last_argument).to eq("hi")
    end
  end
end

