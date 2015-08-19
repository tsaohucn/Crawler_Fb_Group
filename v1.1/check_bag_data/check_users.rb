require 'mongo'
Mongo::Logger.logger.level = ::Logger::FATAL
client = Mongo::Client.new([ '192.168.26.180:27017' ],:database =>'fb_rawdata',:user =>'admin',:password =>'12345')
user = Hash.new(0)
puts "checking users..."
client[:users].find().each do |doc|
	user[doc['app_scoped_user_id']] = doc['name'] if doc['name'].size > 1
end
#user.each do |k,v|
#	puts "#{k}\t#{v}"
#end
puts "共#{user.size}個可疑使用者重複ID"
puts "complicate"