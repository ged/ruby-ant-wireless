#!/usr/bin/env ruby -S rake

require 'rake/deveiate'

Rake::DevEiate.setup( 'ant' ) do |project|
	project.publish_to = 'deveiate:/usr/local/www/public/code'
	project.version_from = 'lib/ant.rb'
end

