
#
# Specifying rufus-lua
#
# Fri Mar 13 23:42:29 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  context 'tables' do

    before do
      @s = Rufus::Lua::State.new
    end
    after do
      @s.close
    end

    it 'finds a hash' do

      @s.eval('h = { a = "b", c = 2, 4 }')

      @s['h'].to_h.should == { 'a' => 'b', 'c' => 2.0, 1.0 => 4.0 }
    end

    it 'turns a hash into an array' do

      @s.eval('a = { "a", "b", "c" }')

      @s['a'].to_h.should == { 1.0 => 'a', 2.0 => 'b', 3.0 => 'c' }
      @s['a'].to_a.should == %w{ a b c }
    end

    it 'does nested lookups (2)' do

      @s.eval('a = { b = { c = 0 } }')

      @s['a.b.c'].should == 0
    end

    it 'returns Lua tables' do

      @s.eval('return {}').class.should == Rufus::Lua::Table
    end

    it 'turns Lua tables into Ruby hashes' do

      @s.eval('return {}').to_h.should == {}
    end

    it 'can free Lua tables' do

      t = @s.eval('t = {}; return t')
      t.free

      t.ref.should == nil
      lambda { t.to_h }.should raise_error(Rufus::Lua::LuaError)
    end

    it 'indexes tables' do

      t = @s.eval("return { a = 'A' }")

      t['a'].should == 'A'
      t['b'].should == nil
    end

    it 'iterates over Lua tables' do

      #t = @s.eval("return { a = 'A', b = 'B', c = 3, d = 3.1 }")
      t = @s.eval("return { a = 'A', b = 'B', c = 3 }")

      t.values.sort_by { |v| v.to_s }.should == [ 3.0, 'A', 'B' ]
      t.keys.sort.should == [ 'a', 'b', 'c' ]
    end

    it 'provides keys and values for tables' do

      t = @s.eval("return { a = 'A', b = 'B', c = 3 }")

      t.collect { |k, v| v }.size.should == 3
    end

    it 'provides the size of a table' do

      @s.eval("return { a = 'A', b = 'B', c = 3 }").objlen.should == 0.0
      @s.eval("return { 1, 2 }").objlen.should == 2

      @s.eval("return { a = 'A', b = 'B', c = 3 }").size.should == 3
      @s.eval("return { a = 'A', b = 'B', c = 3 }").length.should == 3
      @s.eval("return { 1, 2 }").size.should == 2
      @s.eval("return { 1, 2 }").length.should == 2
    end

    it 'lets setting values in Lua tables from Ruby' do

      t = @s.eval("return { a = 'A', b = 'B', c = 3 }")
      t['b'] = 4

      t['b'].should == 4.0
    end

    it 'indexes tables properly' do

      @s.eval("t = { 'a', 'b', 'c' }")

      @s.eval("return t[0]").should == nil
      @s.eval("return t[1]").should == 'a'
      @s.eval("return t[3]").should == 'c'
      @s.eval("return t[4]").should == nil
    end

    it 'replies to to_a(false) (pure = false)' do

      @s.eval("return { a = 'A', b = 'B', c = 3 }").to_a(false).sort.should ==
        [ [ "a", "A" ], [ "b", "B" ], [ "c", 3.0 ] ]
      @s.eval("return { 1, 2 }").to_a(false).should ==
        [ 1.0, 2.0 ]
      @s.eval("return {}").to_a(false).should ==
        []
      @s.eval("return { 1, 2, car = 'benz' }").to_a(false).should ==
        [ 1.0, 2.0, ["car", "benz"] ]
    end

    it 'tries hard to honour #to_ruby' do

      @s.eval("return { a = 'A', b = 'B', c = 3 }").to_ruby.should ==
        { "a" => "A", "b" => "B", "c" => 3.0 }
      @s.eval("return { 1, 2 }").to_ruby.should ==
        [ 1.0, 2.0 ]
      @s.eval("return {}").to_ruby.should ==
        []
      @s.eval("return { 1, 2, car = 'benz' }").to_ruby.should ==
        { 1.0 => 1.0, "car" => "benz", 2.0 => 2.0 }
    end
  end
end

