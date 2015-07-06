require 'net/http'
require 'json'
require './mongo_client'
Mongo::Logger.logger.level = ::Logger::FATAL
APP_ID = "560005114025412"
APP_SECRET = "3b4a90a9890da932c5fe8af1cf2b3809"
fb_token_uri = URI("https://graph.facebook.com/oauth/access_token?client_id=#{APP_ID}&client_secret=#{APP_SECRET}&grant_type=client_credentials")
fb_token = Net::HTTP.get(fb_token_uri)
#fb_token = "CAACEdEose0cBABkYoNoGZAe5H7rAPEiNtK75DR7V7ozk06IeL2JS3LvUMQZCZAZAgEHq8q4NIZBhmiZAMx7HZBnMwWKRIiYycs85iaUikN5iQuS8srQUVZAwZCQD1sOBLgQLupIPiRG731NVI4ChyM3Dww5qIM0LnZCYqQVhiX4YrTaoqrzwKyjITdyMxZAQ70qZAFLQsPqs4cDqogZAkxX9PElCqFF3ZCJGwvilUZD"
client = mongo_client([ '192.168.26.180:27017' ],'fb_group','admin','12345')

#group_id = Array.new(0) { iii }
#group_name = Array.new(0) { iii }
#uri = URI("https://graph.facebook.com/v2.3/me?fields=groups&access_token=#{fb_token}")
#hash = JSON.parse(Net::HTTP.get(uri)) # => String

#hash['groups']['data'].each do |ele|
#	group_id << ele['id']
#	group_name << ele['name']
#end
############open group###############
puts "open group"
File.open('./open_group_id.txt','r+') do |file|
	file.read.each_line do |id|
	now = Time.now
	p now.class
	group_uri = URI("https://graph.facebook.com/v2.3/#{id.chomp}?fields=feed.since(2010-01-01).until(2015-07-01){id,from,to,status_type,created_time,updated_time,message,likes.summary(true),comments.summary(true),shares}&#{fb_token}")
	#group_hash = JSON.parse(Net::HTTP.get(group_uri)) 
	#puts group_hash['feed']['data'].size
	#	group_hash['feed']['data'].each do |doc|
	#		client[:test].insert_one(doc)
	#	end
	#puts "#{id.chomp} OK!!!!"
	end
end
#############close group##############
#puts "close group"
#File.open('./close_group_id.txt','r+') do |file|
#	file.read.each_line do |id|
#	fb_token = "access_token=CAAH9Ulnk1cQBAAAhhTuiZAkzKAXguqxNUrHFt9pRPZCTTOZACzZByICGV5EUlhvBJYtYSmCnVPyaiT4KuxQ1GpBBZCu0ZCfZBxJoxsenHADHH6KMocXmMdWgfLjmF2ZCnc5TuIQIf3sWKq1lU56LfrLsl3aGVv95EfmZA1j5SXLivXRtoenYV1LdqMGaXjoaZBew8ZD"
#	group_uri = URI("https://graph.facebook.com/v2.3/#{id.chomp}?fields=feed.limit(300){id,from,to,status_type,created_time,updated_time,message,likes.summary(true),comments.summary(true),shares}&#{fb_token}")
#	group_hash = JSON.parse(Net::HTTP.get(group_uri)) 
#	puts group_hash
#		group_hash['feed']['data'].each do |doc|
#			client[:test].insert_one(doc)
#		end
#	puts "#{id} OK!!!!"
#	end
#end
