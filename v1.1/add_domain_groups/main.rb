require 'mongo'
require './lib/get_domain_groups.rb'
Mongo::Logger.logger.level = ::Logger::FATAL
client = Mongo::Client.new([ '192.168.26.180:27017' ],:database =>'fb_group',:user =>'admin',:password =>'12345')

get_domain_groups(client)