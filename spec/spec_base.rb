
#
# Specifying rufus-lua
#
# Wed Mar 11 16:09:31 JST 2009
#

#
# bacon

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'rubygems'
require 'fileutils'

$:.unshift(File.expand_path('~/tmp/bacon/lib')) # my own bacon for a while

require 'bacon'

puts

Bacon.summary_on_exit

