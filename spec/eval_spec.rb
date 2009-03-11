
#
# Specifying rufus-lua
#
# Wed Mar 11 17:09:17 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'

require 'rufus/lua'


describe 'Rufus::Lua::State' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should return nil when global not found' do
    @s.unknown.should.be.nil
  end

  it 'should add' do
    @s.eval('a = 1 + 1')
    @s.a.should.equal(2.0)
  end
end

