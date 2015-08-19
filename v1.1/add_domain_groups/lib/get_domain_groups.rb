def get_domain_groups(client)
	domain_keys = ['寶寶']#','孕婦','媽媽','包屁衣']
	domain_uniq_groups = Hash.new(0)
	client[:user_group].find(:user_group_status => "has group").each do |doc|
		if doc['user_group'].size > 0
			doc['user_group'].each do |id,name|
				domain_keys.each do |key|
					#p key
					#puts Regexp.escape(key)
					regular_result = /寶寶/.match(name).to_s
					#puts regular_result
					domain_uniq_groups[id] = name.tr("\n","") if regular_result == key
				end
				#regular_result = /寶寶/.match(name).to_s
				#domain_uniq_groups[id] = name.tr("\n","") if regular_result == '寶寶'
			end
		end
	end

	File.open("./domain_uniq_groups.txt","w+") do |output|
		domain_uniq_groups.each do |k,v|
			output.puts "#{k}\t#{v}"
		end
	end
end