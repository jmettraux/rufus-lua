
#
# Specifying rufus-lua
#
# Thu Jun 19 20:29:06 JST 2014
#

require 'spec_base'


describe Rufus::Lua::Lib do

  describe '.path' do

    it 'returns the Lua lib being used' do

      expect(Rufus::Lua::Lib.path).to match(/liblua/)
    end
  end
end

