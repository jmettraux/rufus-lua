
#
# Specifying rufus-lua
#
# Sat Mar 14 11:39:15 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua (utils)' do

  it 'should turn Ruby arrays into Lua string representations' do

    Rufus::Lua.to_lua_s(%w{ a b c }).should.equal('{ "a", "b", "c" }')
      # TODO : ["a"] is probably better...
  end

  it 'should turn Ruby hashes into Lua string representations' do

    Rufus::Lua.to_lua_s(
      { 'a' => 'A', 'b' => 2}
    ).should.equal(
      '{ ["a"] = "A", ["b"] = 2 }'
    )
  end
end

