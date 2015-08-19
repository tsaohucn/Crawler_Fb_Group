require 'mongo'
Mongo::Logger.logger.level = ::Logger::FATAL
client = Mongo::Client.new([ '192.168.26.180:27017' ],:database =>'fb_group',:user =>'admin',:password =>'12345')