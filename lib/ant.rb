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


	autoload :ResponseCallbacks, 'ant/response_callbacks'


	### Set up the given +mod+ as the handler module for response callbacks.
	def self::set_response_handlers( mod=Ant::ResponseCallbacks )
		self.extend( mod )
		self.on_response( &self.method(:handle_response_callback) )
	end

end # module Ant

