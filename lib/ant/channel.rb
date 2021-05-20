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
	def initialize( channel_number, channel_type, network_number, extended_options )
		self.log.debug "Creating channel #%d" % [ channel_number ]
		@channel_number   = channel_number
		@channel_type     = channel_type
		@network_number   = network_number || DEFAULT_NETWORK_NUMBER
		@extended_options = extended_options || DEFAULT_EXTENDED_OPTIONS
	end


	######
	public
	######

	##
	# The channel number this Channel is assigned
	attr_reader :channel_number

	##
	# The raw numeric channel type
	attr_reader :channel_type

	##
	# The network number the channel is using
	attr_reader :network_number

	##
	# The raw bitmask of extended options for the channel
	attr_reader :extended_options


	### Return a human-readable version of the object suitable for debugging.
	def inspect
		return "#<%p:%#x {%d} %#02x on network %d: %d>" % [
			self.class,
			self.object_id,
			self.channel_number,
			self.channel_type,
			self.network_number,
			self.extended_options,
		]
	end

end # class Ant::Channel

