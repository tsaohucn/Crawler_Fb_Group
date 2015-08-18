def get_user_group(app_scoped_user_id,browser)
	browser.get "https://www.facebook.com/#{app_scoped_user_id}"
	#sleep Random.new.rand(1..10)
	html_check = browser.page_source
	html_check_nokdoc = Nokogiri::HTML(html_check)
	check_tag_set = html_check_nokdoc.xpath("//div/h2[@class='_4-dp']")
	if check_tag_set.none? #check 404
		person_url = browser.current_url
		user_id = person_url.split('=')[1]#find real user id
		group_link = "https://www.facebook.com/profile.php?id=#{user_id}&sk=groups"#find group
		if user_id == nil 
			user_name = person_url.split('/')[3]
			group_link = "https://www.facebook.com/#{user_name}/groups"
		end
		#redirct to user_id'group page
		browser.get group_link
		#sleep Random.new.rand(1..10)
		group_url = browser.current_url
		if group_url != person_url
			user_group = Hash.new(0)
			html_str = browser.page_source
			html_nokdoc = Nokogiri::HTML(html_str)#get group html
			#File.open('./test.txt','w+') do |output|
			#	output.puts html_nokdoc
			#end
			tag_set = html_nokdoc.xpath("//div/div[@class='mtm']/div[@class='mbs fwb']/a")
			#puts tag_set
			tag_set.each do |tag|
				user_group[tag['data-hovercard'].split('=')[1]] = tag.text
			end
			return user_group
		else#no group
			user_group = 'no group'
			return user_group
		end
	else
		user_group = '404'
	end
end