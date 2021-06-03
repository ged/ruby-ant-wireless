# -*- ruby -*-
# frozen_string_literal: true

require 'ant' unless defined?( Ant )


module Ant

	module DataUtilities

		###############
		module_function
		###############

		### Return the given data in hexdump format.
		def hexdump( data, line_size=8 )
			hex_width = line_size * 5
			return data.bytes.each_slice( line_size ).with_index.map do |chunk, line|
				bytes = chunk.map do |b|
					"0x%02x" % [ b ]
				end.join( ' ' )
				stripped_bytes = chunk.pack('C*').gsub( /[\P{print}]/, '.' )
				"%04d: %*s | %*s |" % [ line, -hex_width, bytes, -line_size, stripped_bytes ]
			end.join( "\n" )
		end

	end


end # module Ant
