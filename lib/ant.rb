# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require_relative 'ant_ext'


#--
# See ext/ant_ext/ant_ext.c
module Ant
	extend Loggability

	# Package version
	VERSION = '0.0.1'

	# Version control revision
	REVISION = %q$Revision$

	# Loggability API -- set up a logger for the library
	log_as :ant


	Loggability.level = :debug

	# Set a default response callback that just logs the event
	self.on_response do |channel_num, message_id, data|
		self.log.debug "Response for channel %d: %#0x: %s" % [
			channel_num,
			message_id,
			data.bytes[ 0..3 ].map {|b| "%#02x" % b }.join( ' ' )
		]
	end

end # module Ant

