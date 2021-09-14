# -*- ruby -*-
# frozen_string_literal: true
# vim: set nosta noet ts=4 sw=4:

require 'ant' unless defined?( Ant )

# Ant::BitVector -- a convenience class for manipulating and
# comparing bit vectors.
#
# This is a slightly-modified version of the same utility in StaticCling.
#
# == Synopsis
#
#   require 'ant/bitvector'
#
#   vector = Ant::BitVector.new
#
#   vector.on( 4 )     # => 16
#   vector.on( 12 )    # => 4112
#   vector.toggle( 4 ) # => 4096
#   vector.on?( 4 )    # => false
#   vector.size        # => 13
#   vector.to_hex      # => 0x1000
#
#   vector2 = Ant::BitVector.new( 5 )
#   vector > vector2   # => true
#
#   vector2.each_with_index do |bit, i|
#		puts "Bit %d is %s" % [ i + 1, bit.zero? ? 'off' : 'on' ]
#	end
#
#		Bit 1 is on
#		Bit 2 is off
#		Bit 3 is on
#
# == Version
#
#  $Id$
#
# == Author
#
# * Mahlon E. Smith <mahlon@martini.nu>
#
# == License
#
# Copyright (c) 2000-2013, Mahlon E. Smith <mahlon@martini.nu>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#     * Neither the name of the author, nor the names of contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
class Ant::BitVector
	include Enumerable,
		Comparable

	### Create a new bit vector object, optionally from a pre-existing
	### +init+ number (Any number that ruby supports natively should be
	### fine -- 0b, 0x, or decimal.)
	def initialize( init=0 )
		unless init.respond_to?( :to_i )
			raise ArgumentError, "I don't know what to do with a %s object." % [ init.class.name ]
		end

		@bv = init.to_i
	end


	######
	public
	######

	# let any additional methods fall through to Fixnum/Bignum objs,
	# and return new vector objects.  This allows for doing bitwise math
	# or simple addition/subtraction on two BitVector objects.
	%w{ % & * ** + - / << >> ^ | ~ }.each do |op|
		define_method( op.to_sym ) do |arg|
			res = @bv.send( op.to_sym, arg.bv )
			return self.class.new( res )
		end
	end


	##
	# Allow external access to the underlying Fixnum/Bignum
	attr_reader :bv


	### Return the bit vector as a decimal.
	def to_i
		return @bv
	end
	alias_method :to_int, :to_i
	alias_method :to_dec, :to_i


	### Return the bit vector as a binary string.
	def to_bin
		return "0b%s" % @bv.to_s(2)
	end


	### Return the bit vector as a hexidecimal string.
	def to_hex
		return "0x%04x" % @bv
	end


	### Return the length of the vector in bytes.
	def size
		return @bv.to_s(2).length
	end


	### Switch a +bit+ on.
	def on( bit )
		@bv = @bv | ( 1 << bit )
	end


	### Return boolean true if given +bit+ is currently on.
	def on?( bit )
		return @bv[ bit ].zero? ? false : true
	end
	alias_method :[], :on?


	### Switch a +bit+ off.
	def off( bit )
		@bv = @bv & ~( 1 << bit )
	end


	### Return boolean true if given +bit+ is currently +off+.
	def off?( bit )
		return ! self.on?( bit )
	end


	### Swap the current state of the given +bit+.
	def toggle( bit )
		@bv = @bv ^ ( 1 << bit )
	end
	alias_method :flip, :toggle


	### Set a +bit+ to +bool+ -- either true (on) or false (off).
	### Any value other than nil or false is treated as true.
	### This form also accepts ranges of bits, a la: vector[ 1..4 ] = true
	def []=( bit, bool )
		if bit.respond_to?( :each )
			bit.each { |b| bool ? self.on( b ) : self.off( b ) }
		else
			bool ? self.on( bit ) : self.off( bit )
		end
	end


	### Yield each binary position, least significant +bit+ first.
	def each
		@bv.to_s(2).reverse.each_byte do |bit|
			yield bit.chr.to_i
		end
	end


	### Comparision operator for Comparable mixin, fallthrough to
	### Fixnum/Bignum.  Compares current state against +cmp+.
	def <=>( cmp )
		@bv <=> cmp.bv
	end

end # class Ant::BitVector

