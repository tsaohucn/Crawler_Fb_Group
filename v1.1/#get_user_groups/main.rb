require 'mongo'
require 'selenium-webdriver'
require 'logger'
require './lib/login_fb'
require './lib/get_user_group'

def main(browser)
	###########logger###########
	#logger = Logger.new('log/#get_user_group.log')
    	#logger.progname = '#get_user_group'
    	#logger.level = Logger::WARN
    	#logger.level = Logger::DEBUG
    	##########################
	no_group_count,has_group_count,_404_count = 0,0,0
	Mongo::Logger.logger.level = ::Logger::FATAL
	client = Mongo::Client.new([ '192.168.26.180:27017' ],:database =>'fb_rawdata',:user =>'admin',:password =>'12345')
	doc_set = client[:users].find({:doc_status => "never update"})
	puts "Get #{doc_set.count.to_i} users  need to update groups"
	doc_set.each do |doc|
		user_group = get_user_group(doc['app_scoped_user_id'],doc['name'][0],browser)
		break if _404_count >= 10
		if user_group == 'no group'
			result = client[:users].find(:app_scoped_user_id => doc['app_scoped_user_id']).update_one('$set' => { :doc_status => "no group",:latest_update_time => Time.now })
			if result.n == 1
				no_group_count += 1
				puts "\"#{doc['app_scoped_user_id']}\" \"#{doc['name'][0]}\"...沒有公開社團(#{no_group_count})"
			end
		elsif user_group == '404'
			result = client[:users].find(:app_scoped_user_id => doc['app_scoped_user_id']).update_one('$set' => { :doc_status => "404",:latest_update_time => Time.now })
			if result.n == 1
				_404_count += 1
				puts "\"#{doc['app_scoped_user_id']}\" \"#{doc['name'][0]}\"...404(#{_404_count})"
			end
		else
			result = client[:users].find(:app_scoped_user_id => doc['app_scoped_user_id']).update_one('$set' => { :doc_status => "has group",:groups => user_group,:latest_update_time => Time.now })
			if result.n == 1
				has_group_count += 1
				puts "\"#{doc['app_scoped_user_id']}\" \"#{doc['name'][0]}\"...抓到#{user_group.size}個公開社團(#{has_group_count})"
			end
		end
	end
	File.open('./log/grap_history.log','a+') do |output|
		output.puts "#{Time.now}\t#{has_group_count}\t#{no_group_count}"
	end
	#browser.quit
	return browser
end
############Tiltle Message############
BEGIN{
	time_start = Time.now 
	puts "=================Start : #get_user_groups================="
}
END{
	puts "==================End : #get_user_groups=================="
	time_end = Time.now 
	puts "Time cost : #{Time.at(time_end-time_start).utc.strftime("%H:%M:%S")}"
}
############Main Program############
#begin

	File.open('./log/grap_history.log','w+') do |output|
		output.puts "時間\t有公開社團\t沒有公開社團\t"
	end
	browser = login_fb()
	while true
		browser = main(browser)
		puts "sleeping 10 minutes..."
		sleep(10*60)
	end
#rescue Exception => ex
#	$stderr.puts ex.message
  #	$stderr.puts ex.backtrace.join("\n")
#end
#get_user_group("100010242033753","王麗嬰",browser)
#get_user_group("1020407414645839","Dissy Chou",browser)
#get_user_group("287292","Dissy Chou",browser)
#get_user_group("100000133512642","林艾薇",browser)