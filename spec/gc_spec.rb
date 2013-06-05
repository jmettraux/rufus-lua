
#
# Specifying rufus-lua
#
# Mon Mar 16 23:07:49 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  describe '#gc_collect!' do

    it 'raises when called on a closed Rufus::Lua::State instance' do

      s = Rufus::Lua::State.new
      s.close
      lambda { s.gc_collect! }.should raise_error(RuntimeError)
    end
  end

  describe '#gc_count' do

    it 'returns an indication about the Lua interpreter memory usage' do

      before_usage = @s.gc_count
      @s.eval("return table.concat({ 'hello', 'from', 'Lua' }, ' ')")
      after_usage = @s.gc_count

      after_usage.should > before_usage
    end
  end
end
