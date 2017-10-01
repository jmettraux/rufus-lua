
module Rufus::Lua

  #--
  # always make sure that the methods here are usable without the need
  # to load liblua.dylib
  #++

  # Turns a Ruby instance into a Lua parseable string representation.
  #
  # Will raise an ArgumentError as soon as something else than a simple
  # Ruby type (or Hash/Array) is passed.
  #
  #   Rufus::Lua.to_lua_s({ 'a' => 'A', 'b' => 2})
  #     #
  #     # => '{ "a": "A", "b": 2 }'
  #
  def self.to_lua_s(o)

    case o

      when String then o.inspect
      when Fixnum then o.to_s
      when Float then o.to_s
      when TrueClass then o.to_s
      when FalseClass then o.to_s
      when NilClass then 'nil'

      when Hash then to_lua_table_s(o)
      when Array then to_lua_table_s(o)

      else raise(
        ArgumentError.new(
          "don't how to turning into a Lua string representation "+
          "Ruby instances of class '#{o.class}'"))
    end
  end

  # Turns a Ruby Array or Hash instance into a Lua parseable string
  # representation.
  #
  def self.to_lua_table_s(o)

    s = if o.is_a?(Array)
      o.collect { |e| to_lua_s(e) }
    else
      o.collect { |k, v| "[#{to_lua_s(k)}] = #{to_lua_s(v)}" }
    end

    "{ #{s.join(', ')} }"
  end
end

