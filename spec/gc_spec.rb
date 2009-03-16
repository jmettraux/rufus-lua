
#
# Specifying rufus-lua
#
# Mon Mar 16 23:07:49 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State (gc)' do

  it 'should call functions with arguments' do

    @s = Rufus::Lua::State.new
    @s.close

    should.raise(RuntimeError) { @s.gc_collect! }
  end

  it 'should accurately count Lua interpreter memory usage' do

    @s = Rufus::Lua::State.new

    before_usage = @s.gc_count
    @s.eval("return table.concat({ 'hello', 'from', 'Lua' }, ' ')")
    after_usage = @s.gc_count

    after_usage.should.> before_usage
  end
end
