require 'net/http'
require 'json'

fb_token = "CAACEdEose0cBAJ5lzNowVadtMQjnxX9rsUtzkv3qGnYLxZBf1oFZC3xYJNb6y6xMcHA5ryzG6OcZANixN0ZAPDtBqR6O5tCzuACj8vZANyG3fhEPIE3ZBDWKBFubVWzwbA3hLhtafdwTOjFszGcgk43D48XKlscdQnqo4Ekq7wx2NN8O2RWS4rK5ybXTtRZBoMa3ZC9XzubBelfRhZCobYEAsBUaM6SdebwQZD"

group_id = Array.new(0) { iii }
group_name = Array.new(0) { iii }
uri = URI("https://graph.facebook.com/v2.3/me?fields=groups&access_token=#{fb_token}")
hash = JSON.parse(Net::HTTP.get(uri)) # => String

hash['groups']['data'].each do |ele|
	group_id << ele['id']
	group_name << ele['name']
end
id = '1408421489407690'
mess = Array.new(0) { iii }
#group_id.each do |id|
	group_uri = URI("https://graph.facebook.com/v2.3/#{id}?fields=feed&access_token=#{fb_token}")
	group_hash = JSON.parse(Net::HTTP.get(group_uri)) 
	group_hash['feed']['data'].each do |ele|
		mess << ele['message']
	end
#end
File.open('fb_group.txt','w+') do |output|
	mess.each do |ele|
		output.puts ele
	end
end

