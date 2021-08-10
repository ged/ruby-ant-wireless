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


	#
	# Autoloads
	#

	autoload :EventCallbacks, 'ant/channel/event_callbacks'


	# Loggability API -- log to the Ant logger
	log_to :ant

	# Disallow manual instantiation
	private_class_method :new


	##
	# :singleton-method: registry
	# Channel registry, keyed by channel number.
	singleton_class.attr_reader( :registry )


	######
	public
	######

	alias_method :set_channel_rf_frequency, :set_channel_rf_freq


	### Set up the given +mod+ as the handler module for channel events.
	def set_event_handlers( object=Ant::Channel::EventCallbacks )
		self.on_event( &object.method(:handle_event_callback) )
	end


	### Return a human-readable version of the object suitable for debugging.
	def inspect
		return "#<%p:%#x {%d} %#02x on network %d: %d%s>" % [
			self.class,
			self.object_id,
			self.channel_number,
			self.channel_type,
			self.network_number,
			self.extended_options,
			self.closed? ? " (closed)" : "",
		]
	end

end # class Ant::Channel

