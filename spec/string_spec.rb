
#
# Specifying rufus-lua
#
# Sat Jun 21 11:04:02 JST 2014
#

require 'spec_base'

# adapted from https://github.com/jmettraux/rufus-lua/issues/14


describe 'lua strings' do

  context 'and \0 bytes' do

    before :each do
      @s = Rufus::Lua::State.new
    end
    after :each do
      @s.close
    end

    it 'are not truncated when returned to Ruby' do

      s = @s.eval('return string.char(1, 0, 0)')

      expect(s.bytes.to_a).to eq([ 1, 0, 0 ])
    end

    it 'are not truncated when passed from Ruby to Lua and back' do

      s = [ 65, 66, 0, 67, 68 ].pack('c*')

      f = @s.eval(%{
        f = function(s)
          return { s = s, l = string.len(s) }
        end
        return f
      })

      expect(f.call(s).to_h).to eq({ 's' => s, 'l' => 5 })
    end

    it 'fetch nully strings from stack' do 
      expect(@s.eval("return string.char(32,0,0,32)")).to eq("\x20\x00\x00\x20")
      expect(@s.eval("return string.char(32,0,0,32)").length).to eq(4)
    end

    it 'verify ruby string behavior' do
      nullstr = "\x20\x00\x00\x20"
      expect(nullstr.size).to eq(4)
      expect(nullstr.getbyte(3)).to eq(32)
    end 

    it 'push nully strings to stack' do 
      nullstr = "\x20\x00\x00\x20"
      @s.function "get_null_string" do
        nullstr
      end
      expect(@s.eval("return string.len(get_null_string())")).to eq(4)
      expect(@s.eval("return string.byte(get_null_string(),4)")).to eq(32)

      expect(@s.eval("return (get_null_string() == string.char(32,0,0,32))")).to eq(true)
      
      str = @s.eval("return string.char(32,0,0,32)")
      expect(str.length).to eq(4) 
      expect(str).to eq(nullstr) 
    end
  
    it 'roundtrips null bytes' do
      #Here we verify roundtripping from both sides
      #Note that length checking is just to make sure the nullcounters don't activate
      output = {}
      @s.function "save_out" do |k, v|
        output[k] = v
      end
      @s.function "pull_in" do |k|
        output[k]
      end
      @s.eval(%{
        s = string.char(32,0,32)
        save_out("copy",s)
        s = pull_in("copy")
        save_out("length",string.len(s))
        save_out("byte0", string.byte(s,1))
        save_out("byte1", string.byte(s,2))
        save_out("byte2", string.byte(s,3))
        save_out("copy2",s)})
      expect(output["copy2"]).to eq("\x20\x00\x20")
      expect(output["byte0"]).to eq(32.0)
      expect(output["byte1"]).to eq(0.0)
      expect(output["byte2"]).to eq(32.0)
      expect(output["length"]).to eq(3)
    end

    it 'should not convert a string into a function' do
      @s.function "host_function" do
        "success"
      end
      expect(@s.eval(%{
        function routine()
          local retval = host_function()
          return retval
        end
        return routine()})).to eq("success")
    end

    it 'should not convert a string into a function when coroutines are in use' do
      @s.function "host_function" do
        "success"
      end
      expect(@s.eval(%{
        function hf()
          return host_function()
        end
        env = {tostring=tostring,cy = coroutine.yield,hostfunc=hf}
        env["_G"] = env

        function routine()
          local retval = hostfunc()
          cy(retval)
        end
        setfenv(routine, env)
        co = coroutine.create(routine)
        a, b = coroutine.resume(co)
        return {a,b}}).to_ruby).to eq([true,"success"])
    end
  end
end

