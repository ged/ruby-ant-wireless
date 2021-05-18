#!/usr/bin/env ruby

BEGIN {
	$LOAD_PATH.unshift 'lib', '../lib'
}

require 'ant'


class Chatter

	### (Undocumented)
	def self::run( args )
		mode = args.shift or abort "Usage: #$0 [MODE]"
		case mode
		when 'master'
			return self.run_as_master( args )
		when 'slave'
			return self.run_as_slave( args )
		else
			abort "Invalid mode %p" % [ mode ]
		end
	end



end


if __FILE__ == $0
	Chatter.run( ARGV )
end