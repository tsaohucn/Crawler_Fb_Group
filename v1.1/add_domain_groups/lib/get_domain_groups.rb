def get_domain_groups(client)
	domain_keys = ['寶寶','孕婦','媽媽','包屁衣']
	domain_uniq_groups = Hash.new(0)
	client[:users].find({:doc_status => "has group"}).each do |doc|
		if doc['groups'].class == BSON::Document and doc['groups'].count > 0
			doc['groups'].each do |id,name|
				domain_keys.each do |key|
					regular_result = /#{Regexp.escape(key)}/.match(name).to_s
					domain_uniq_groups[id] = name.tr("\n","") if regular_result == key
				end
			end
		end
	end

	File.open("./domain_uniq_groups.txt","w+") do |output|
		domain_uniq_groups.each do |k,v|
			output.puts "#{k}\t#{v}"
		end
	end
	
end