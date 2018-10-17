
#
# Specifying rufus-lua
#
# Thu Jun 19 20:29:06 JST 2014
#

require 'spec_base'


describe Rufus::Lua::Lib do

  describe '.path' do

    it 'returns the Lua lib being used' do

      path =
        Array(
          [ ENV['LUA_LIB'] ].compact +
          Dir.glob('/usr/lib/liblua*.so') +
          Dir.glob('/usr/lib/*/liblua*.so') +
          Dir.glob('/usr/local/lib/liblua*.so') +
          Dir.glob('/opt/local/lib/liblua*.so') +
          Dir.glob('/usr/lib/liblua*.dylib') +
          Dir.glob('/usr/local/lib/liblua*.dylib') +
          Dir.glob('/opt/local/lib/liblua*.dylib')
        ).first

      expect(Rufus::Lua::Lib.path).to eq path
    end
  end
end

