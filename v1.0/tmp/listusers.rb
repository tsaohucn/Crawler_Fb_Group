
@dir_path = 'actions130731'

def get_user_list(file_name)
	result = Array.new
	File.open(@dir_path + '/' + file_name, 'r').each{ |line|
		next if line.match(/^#/)
		data = line.split
		uid = data[0]
		result << uid
	}
	result
end

def get_users
	files = Array.new
	Dir.new(@dir_path).each { |x|
		files << x if x.match(/_users\.txt/)
	}

	users = Array.new
	files.each { |file_name|
		puts file_name
		users.concat get_user_list(file_name)
		users.uniq!
	}

	File.open('user_list.txt', 'w+') { |f|
		users.each { |u| f.puts u }
	}

	puts "Total #{users.size} users"
end

def eval_users(file_name)
	#files = Array.new
	#Dir.new(@dir_path).each { |x|
	#	files << x if x.match(/_actions\.txt/)
	#}
	#files << '5981562499_actions.txt'

	users = Array.new
	monthly_users = Hash.new{|hash, key| hash[key] = Hash.new(0)}
	monthly_users_c = Hash.new{|hash, key| hash[key] = Hash.new(0)}
	monthly_users_l = Hash.new{|hash, key| hash[key] = Hash.new(0)}

	#files.each { |file_name|
		puts file_name
		File.open(@dir_path + '/' + file_name, 'r').each{ |line|
			#next if line.match(/^#/)
			data = line.split
			date = data[0]
			uid = data[1]
			target = data[2]
			action = data[3]
			monthly_users[date[0..6]][uid] += 1
			monthly_users_c[date[0..6]][uid] += 1 if action == 'comment'
			monthly_users_l[date[0..6]][uid] += 1 if action == 'like'
			users << uid
		}
		users.uniq!
	#}

	File.open('monthly_users/(comments+likes)' + file_name, 'w+') { |f|
		f.print 'user/month'
		monthly_users.sort.each { |k,_| f.print "\t", k}
		f.puts "\ttotal"
		users.each { |uid|
			f.print uid
			sum = 0
			monthly_users.sort.each { |k,_|
				sum += monthly_users[k][uid]
				f.print "\t", monthly_users[k][uid]
			}
			f.puts "\t#{sum}"
		}
	}

	File.open('monthly_users/comments_' + file_name, 'w+') { |f|
		f.print 'user/month'
		monthly_users_c.sort.each { |k,_| f.print "\t", k}
		f.puts "\ttotal"
		users.each { |uid|
			f.print uid
			sum = 0
			monthly_users_c.sort.each { |k,_|
				sum += monthly_users_c[k][uid]
				f.print "\t", monthly_users_c[k][uid]
			}
			f.puts "\t#{sum}"
		}
	}

	File.open('monthly_users/likes_' + file_name, 'w+') { |f|
		f.print 'user/month'
		monthly_users_l.sort.each { |k,_| f.print "\t", k}
		f.puts "\ttotal"
		users.each { |uid|
			f.print uid
			sum = 0
			monthly_users_l.sort.each { |k,_|
				sum += monthly_users_l[k][uid]
				f.print "\t", monthly_users_l[k][uid]
			}
			f.puts "\t#{sum}"
		}
	}
end

def relation_compute
	path = 'old_actions130723'
	files = Array.new
	page_ids = Array.new
	Dir.new(path).each { |x|
		m = x.match(/(\d+)_actions\.txt/)
		files << x unless m.nil?
		page_ids << m[1] unless m.nil?
	}

	#files.each { |file_name|
	#	puts 'processing ' + file_name + ' ...'
	#}
	user_comments = Hash.new{|hash, key| hash[key] = Hash.new(0)}
	page_ids.each { |page_id|
		file_name = page_id + '_actions.txt'
		puts 'processing ' + file_name + ' ...'

		File.open(path + '/' + file_name, 'r').each{ |line|
			#next if line.match(/^#/)
			data = line.split
			date = data[0]
			uid = data[1]
			target = data[2]
			action = data[3]
			next if uid == page_id # ignore company comments
			user_comments[uid][page_id] += 1 if action == 'comment' || action == 'post'
			#monthly_users[date[0..6]][uid] += 1
			#monthly_users_c[date[0..6]][uid] += 1 if action == 'comment'
			#monthly_users_l[date[0..6]][uid] += 1 if action == 'like'
			#users << uid
		}
	}

	puts user_comments.size

	File.open('user_comments.txt', 'w+') { |file|
		data = ['#user/page']
		data.concat page_ids
		#page_ids.each { |page_id| data << page_id }
		file.puts data.join("\t")
		user_comments.each { |k,v|
			data.clear
			data << k # user id
			sum = 0
			page_ids.each { |page_id|
				sum += v[page_id]
				data << v[page_id]
			}
			file.puts data.join("\t") if sum > 100
		}
	}

end

def main
	files = Array.new
	path = @dir_path
	path = 'old_actions130723'
	Dir.new(path).each { |x|
		files << x if x.match(/_actions\.txt/)
	}
	#files << '5981562499_actions.txt'
	files.each { |file_name|
		#eval_users(file_name)
	}

	relation_compute
end

main
