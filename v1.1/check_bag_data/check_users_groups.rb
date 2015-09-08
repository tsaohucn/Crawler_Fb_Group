require 'mongo'
Mongo::Logger.logger.level = ::Logger::FATAL
client = Mongo::Client.new([ '192.168.26.180:27017' ],:database =>'fb_rawdata',:user =>'admin',:password =>'12345')
has_group_set = client[:users].find(:doc_status => "has group")
#_404_set = client[:users].find(:doc_status => "404")
no_group_set = client[:users].find(:doc_status => "no group")
never_update_set = client[:users].find(:doc_status => "never update")
#error_set = client[:users].find(:doc_status => "error")
#puts "erroe : #{error_set.count.to_i}"
#puts "404 : #{_404_set.count.to_i}"
puts "never update : #{never_update_set.count.to_i}"
puts "has group : #{has_group_set.count.to_i}"
puts "no group : #{no_group_set.count.to_i}"
unique_group = Hash.new{|k,v| unique_group[v] = Array.new(0)}
group_count = 0
unique_group_count = 0
double_group_count = 0
has_group_set.each do |doc|
	if doc['groups'].size > 0
		group_count = group_count + doc['groups'].size
		doc['groups'].each do |k,v|
			unique_group[k] << v
		end
	end
end
#unique_group_id_count =  unique_group.keys.size
double_group = Hash.new(0)
unique_group.each do |k,v|
	v = v.uniq
	unique_group[k] = v
	if v.size  > 1
		double_group_count += 1
		double_group[k] = v
	else
		unique_group_count += 1
	end
end
puts "Total groups : #{group_count}"
puts "Total unique groups : #{unique_group_count}"
puts "Total double groups : #{double_group_count}"
File.open('./unique_group.txt','w+') do |output|
	unique_group.each  do |k,v|
		output.puts "#{k}\t#{v}"
	end
end
File.open('./double_group.txt','w+') do |output|
	double_group.each  do |k,v|
		output.puts "#{k}\t#{v}"
	end
end