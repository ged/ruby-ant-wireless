# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'


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

	require_relative 'ant_ext'


	# Log responses unless the callback is overridden
	self.on_response do |channel, message_id|
		self.log.debug "Got response for channel %d: %#x" % [ channel, message_id ]
	end

end # module Ant

