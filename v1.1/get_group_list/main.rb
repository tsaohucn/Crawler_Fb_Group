require 'selenium-webdriver'
require 'nokogiri'
require 'mongo'
require './login_fb'
require './get_user_group'

begin
	time_start = Time.now
 	puts "Start: #{time_start}"
  	puts "========================================"
  	browser = login_fb()
  	user_group = get_user_group("100010242033753",browser)
  	Mongo::Logger.logger.level = ::Logger::FATAL
	client = Mongo::Client.new([ '192.168.26.180:27017' ],:database =>'fb_rawdata',:user =>'admin',:password =>'12345')
	client[:groups_list].find().find_one_and_replace(user_group)
  	browser.quit
rescue => ex
  $stderr.puts ex.message
  $stderr.puts ex.backtrace.join("\n")
ensure
	time_end = Time.now
  	puts "========================================"
  	puts "End: #{time_end}"
  	puts "Time cost: #{time_end - time_start}"
end