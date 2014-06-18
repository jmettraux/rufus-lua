
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

      expect(@s['h'].to_h).to eq({ 'a' => 'b', 'c' => 2.0, 1.0 => 4.0 })
    end

    it 'turns a hash into an array' do

      @s.eval('a = { "a", "b", "c" }')

      expect(@s['a'].to_h).to eq({ 1.0 => 'a', 2.0 => 'b', 3.0 => 'c' })
      expect(@s['a'].to_a).to eq %w{ a b c }
    end

    it 'does nested lookups (2)' do

      @s.eval('a = { b = { c = 0 } }')

      expect(@s['a.b.c']).to eq 0
    end

    it 'returns Lua tables' do

      expect(@s.eval('return {}').class).to eq Rufus::Lua::Table
    end

    it 'turns Lua tables into Ruby hashes' do

      expect(@s.eval('return {}').to_h).to eq({})
    end

    it 'can free Lua tables' do

      t = @s.eval('t = {}; return t')
      t.free

      expect(t.ref).to eq nil
      expect(lambda { t.to_h }).to raise_error(Rufus::Lua::LuaError)
    end

    it 'indexes tables' do

      t = @s.eval("return { a = 'A' }")

      expect(t['a']).to eq 'A'
      expect(t['b']).to eq nil
    end

    it 'iterates over Lua tables' do

      #t = @s.eval("return { a = 'A', b = 'B', c = 3, d = 3.1 }")
      t = @s.eval("return { a = 'A', b = 'B', c = 3 }")

      expect(t.values.sort_by { |v| v.to_s }).to eq [ 3.0, 'A', 'B' ]
      expect(t.keys.sort).to eq [ 'a', 'b', 'c' ]
    end

    it 'provides keys and values for tables' do

      t = @s.eval("return { a = 'A', b = 'B', c = 3 }")

      expect(t.collect { |k, v| v }.size).to eq 3
    end

    it 'provides the size of a table' do

      expect(@s.eval("return { a = 'A', b = 'B', c = 3 }").objlen).to eq 0.0
      expect(@s.eval("return { 1, 2 }").objlen).to eq 2

      expect(@s.eval("return { a = 'A', b = 'B', c = 3 }").size).to eq 3
      expect(@s.eval("return { a = 'A', b = 'B', c = 3 }").length).to eq 3
      expect(@s.eval("return { 1, 2 }").size).to eq 2
      expect(@s.eval("return { 1, 2 }").length).to eq 2
    end

    it 'lets setting values in Lua tables from Ruby' do

      t = @s.eval("return { a = 'A', b = 'B', c = 3 }")
      t['b'] = 4

      expect(t['b']).to eq 4.0
    end

    it 'indexes tables properly' do

      @s.eval("t = { 'a', 'b', 'c' }")

      expect(@s.eval("return t[0]")).to eq nil
      expect(@s.eval("return t[1]")).to eq 'a'
      expect(@s.eval("return t[3]")).to eq 'c'
      expect(@s.eval("return t[4]")).to eq nil
    end

    it 'replies to to_a(false) (pure = false)' do

      expect(@s.eval(
        "return { a = 'A', b = 'B', c = 3 }"
      ).to_a(false).sort).to eq(
        [ [ "a", "A" ], [ "b", "B" ], [ "c", 3.0 ] ]
      )
      expect(@s.eval(
        "return { 1, 2 }"
      ).to_a(false)).to eq(
        [ 1.0, 2.0 ]
      )
      expect(@s.eval(
        "return {}"
      ).to_a(false)).to eq(
        []
      )
      expect(@s.eval(
        "return { 1, 2, car = 'benz' }"
      ).to_a(false)).to eq(
        [ 1.0, 2.0, ["car", "benz"] ]
      )
    end

    it 'tries hard to honour #to_ruby' do

      expect(@s.eval(
        "return { a = 'A', b = 'B', c = 3 }"
      ).to_ruby).to eq(
        { "a" => "A", "b" => "B", "c" => 3.0 }
      )
      expect(@s.eval(
        "return { 1, 2 }"
      ).to_ruby).to eq(
        [ 1.0, 2.0 ]
      )
      expect(@s.eval(
        "return {}"
      ).to_ruby).to eq(
        []
      )
      expect(@s.eval(
        "return { 1, 2, car = 'benz' }"
      ).to_ruby).to eq(
        { 1.0 => 1.0, "car" => "benz", 2.0 => 2.0 }
      )
    end
  end
end

