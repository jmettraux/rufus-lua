
#
# Specifying rufus-lua
#
# Mon Mar 16 23:38:00 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe Rufus::Lua::State do

  it 'should not crash closing a closed State' do

    @s = Rufus::Lua::State.new
    @s.close

    should.raise(RuntimeError) { @s.close }
  end
end

describe Rufus::Lua::State do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should return nil for unbound variables' do

    @s['a'].should.be.nil
  end

  it 'should accept setting values directly' do

    @s['a'] = 1
    @s['a'].should.equal(1)
  end

  it 'should accept setting array values directly' do

    @s['a'] = [ true, false, %w[ alpha bravo charly ] ]
    @s['a'].to_a[0].should.equal(true)
    @s['a'].to_a[2].to_a.should.equal(%w[ alpha bravo charly ])
  end

  it 'should accept setting hash values directly' do

    @s['a'] = { 'a' => 'alpha', 'b' => 'bravo' }
    @s['a'].to_h.should.equal({ 'a' => 'alpha', 'b' => 'bravo' })
  end
end

