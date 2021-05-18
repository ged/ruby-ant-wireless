# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'ant' unless defined?( Ant )


class Ant::Channel
	extend Loggability

	# The default network number
	DEFAULT_NETWORK_NUMBER = 0

	# The default channel options
	DEFAULT_EXTENDED_OPTIONS = 0x0


	# Loggability API -- log to the Ant logger
	log_to :ant

	# Disallow manual instantiation
	private_class_method :new


	### Create a new channel with the given
	def initialize( channel, channel_type, network_number, extended_options )
		@channel          = channel
		@channel_type     = channel_type
		@network_number   = network_number || DEFAULT_NETWORK_NUMBER
		@extended_options = extended_options || DEFAULT_EXTENDED_OPTIONS
	end


	######
	public
	######

	##
	# The channel number this Channel is assigned
	attr_reader :channel

	##
	# The raw numeric channel type
	attr_reader :channel_type

	##
	# The network number the channel is using
	attr_reader :network_number

	##
	# The raw bitmask of extended options for the channel
	attr_reader :extended_options



end # class Ant::Channel

