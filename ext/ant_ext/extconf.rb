#!/usr/bin/env ruby

require 'rbconfig'
require 'mkmf'

dir_config( 'libant' )

have_library( 'ant' ) or
	abort "No ant library!"

have_header( 'ant.h' ) or
	abort "No ant.h header!"
have_header( 'ruby/thread.h' ) or
	abort "Your Ruby is too old!"

have_func( 'ANT_LibVersion', 'ant.h' )
have_func( 'ANT_GetDeviceSerialNumber', 'ant.h' )

create_header()
create_makefile( 'ant_ext' )

