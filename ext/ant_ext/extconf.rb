#!/usr/bin/env ruby

require 'rbconfig'
require 'mkmf'

dir_config( 'libant' )

have_library( 'ant' ) or
	abort "No ant library!"

have_header( 'libant.h' ) or
	abort "No libant.h header!"
have_header( 'ruby/thread.h' ) or
	abort "Your Ruby is too old!"

have_func( 'ANT_Init', 'libant.h' )
have_func( 'ANT_IsInitialized', 'libant.h' )
have_func( 'ANT_LibVersion', 'libant.h' )
have_func( 'ANT_GetDeviceSerialNumber', 'libant.h' )

# Ref: https://bugs.ruby-lang.org/issues/17865
$CPPFLAGS << " -Wno-compound-token-split-by-macro "

$CFLAGS << " -g "

create_header()
create_makefile( 'ant_ext' )

