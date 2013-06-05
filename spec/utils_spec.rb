
#
# Specifying rufus-lua
#
# Sat Mar 14 11:39:15 JST 2009
#

require 'spec_base'


describe Rufus::Lua do

  context '(utils)' do

    it 'turns Ruby arrays into Lua string representations' do

      Rufus::Lua.to_lua_s(
        %w{ a b c }
      ).should ==
        '{ "a", "b", "c" }'

      # TODO : ["a"] is probably better...
    end

    it 'turns Ruby hashes into Lua string representations' do

      Rufus::Lua.to_lua_s(
        { 'a' => 'A', 'b' => 2}
      ).should ==
        '{ ["a"] = "A", ["b"] = 2 }'
    end
  end
end

