# -*- ruby -*-
# frozen_string_literal: true

require_relative 'spec_helper'

require 'ant/bitvector'


RSpec.describe( Ant::BitVector ) do

	context 'when first instantiated' do

		it "is empty when created without arguments" do
			v = described_class.new
			expect( v.to_i ).to eq( 0 )
			expect( v.size ).to eq( 1 )
		end


		it "accepts a decimal argument" do
			v = described_class.new( 242 )
			expect( v.to_hex ).to eq( '0x00f2' )
		end


		it "accepts a hexadecimal argument" do
			v = described_class.new( 0x00f2 )
			expect( v.to_i ).to eq( 242 )
		end


		it "accepts a bit string argument" do
			v = described_class.new( 0b11110010 )
			expect( v.to_i ).to eq( 242 )
		end


		it "accepts a different BitVector argument" do
			v = described_class.new( described_class.new( 242 ) )
			expect( v.to_i ).to eq( 242 )
		end


		it "accepts a string argument" do
			v = described_class.new( "242" )
			expect( v.to_i ).to eq( 242 )
		end


		it "rejects objects that don't have a 'to_i' method" do
			expect {
				described_class.new( Class )
			}.to raise_error( ArgumentError, /don't know what to do/i )
		end

	end


	context 'after modified with a value' do

		let( :bv ) { described_class.new( 242 ) }


		it "can be converted into various formats" do
			expect( bv.to_int ).to eq( 242 )
			expect( bv.to_hex ).to eq( '0x00f2' )
			expect( bv.to_bin ).to eq( '0b11110010' )
		end


		it "knows the size of its own bit string" do
			expect( bv.size ).to eq( 8 )
			bv.toggle( 9 )
			expect( bv.size ).to eq( 10 )
		end


		it "can switch specific bits on and off" do
			expect( bv.on?( 12 ) ).to be_falsey

			bv.on( 12 )
			expect( bv[12] ).to be_truthy

			bv.off( 12 )
			expect( bv.off?( 12 ) ).to be_truthy

			bv[12] = true
			expect( bv.on?( 12 ) ).to be_truthy
		end


		it "can set bits in a range" do
			expect( bv[ 8] ).to be_falsey
			expect( bv[ 9] ).to be_falsey
			expect( bv[10] ).to be_falsey
			expect( bv[11] ).to be_falsey
			expect( bv[12] ).to be_falsey

			bv[8..12] = true

			expect( bv[ 8] ).to be_truthy
			expect( bv[ 9] ).to be_truthy
			expect( bv[10] ).to be_truthy
			expect( bv[11] ).to be_truthy
			expect( bv[12] ).to be_truthy
		end


		it "delegates math operations to the underlying integer" do
			bv2 = described_class.new( 4112 )

			bv3 = bv + bv2
			expect( bv3.to_int ).to eq( 4354 )

			bv3 = bv | bv2
			expect( bv3.to_int ).to eq( 4338 )

			bv3 = bv & bv2
			expect( bv3.to_int ).to eq( 16 )

			expect( bv3 ).to be_a( described_class )
		end


		it "can compare different bitvector objects" do
			bv1 = described_class.new( bv )
			bv2 = described_class.new( 4112 )
			expect( bv ).to eq( bv1 )
			expect( bv ).to be < bv2
		end


		it "is enumerable" do
			bits = bv.to_a
			expect( bits ).to eq( [0, 1, 0, 0, 1, 1, 1, 1] )
		end

	end

end

