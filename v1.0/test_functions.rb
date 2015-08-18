
def output_users(myfb, page_id)
  pcoll = myfb.mongo_db[TABLE_POSTS]
  ccoll = myfb.mongo_db[TABLE_COMMENTS]
  lcoll = myfb.mongo_db[TABLE_LIKES]

  posters_clist = Hash.new(0)
  posters_llist = Hash.new(0)
  posters_name = {}
  daily_comments = Hash.new(0)
  daily_likes = Hash.new(0)
  daily_total = Hash.new(0)
  monthly_comments = Hash.new(0)
  monthly_likes = Hash.new(0) 
  monthly_total = Hash.new(0)
  monthly_users = Hash.new{|hash, key| hash[key] = Array.new}
  
  convert_time = lambda { |t| t.strftime("%Y-%m-%d")}

  find_target = {'page_id' => page_id}
  
  comments_count = 0
  likes_count = 0

  file_actions = File.open("./tmp/#{page_id}_actions.txt", 'w+')

  fields = {'_id' => 1, 'page_id' => 1, 'post_time' => 1}
  find_opts = {:fields => fields}
  post_time_list = Hash[ pcoll.find(find_target,find_opts).map { |post| [post['_id'], post['post_time']] } ]
  puts "INFO: #{post_time_list.size} posts are processed"

  fields = {'_id' => 1, 'page_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1}
  find_opts = {:fields => fields}
  # Read each comments
  ccoll.find(find_target, find_opts).each{ |post|
    next unless post.has_key?('doc')
    post_time = convert_time.call( post_time_list[post['_id']] )
    comments_count += post['doc'].size
    daily_comments[post_time] += post['doc'].size
    daily_total[post_time] += post['doc'].size

    next if post['doc'].nil?
    post['doc'].each{ |e|
      next unless e.has_key?('from')
      next if e['from'].nil?
      tid = e['from']['id']
      tname = e['from']['name']

      posters_clist[tid] += 1
      posters_name[tid] = tname
      monthly_users[post_time[0..6]].push(tid)
      # output actions
      file_actions.puts "#{post_time}\t#{tid}\t#{page_id}\tcomment"
    }
  }
  puts "INFO: #{comments_count} comments are processed"

  # Read each likes id
  lcoll.find(find_target, find_opts).each{ |post|
    next unless post.has_key?('doc')
    post_time = convert_time.call( post_time_list[post['_id']] )
    likes_count += post['doc'].size
    daily_likes[post_time] += post['doc'].size
    daily_total[post_time] += post['doc'].size

    post['doc'].each{ |e|
      tid = e['id']
      tname = e['name']

      posters_llist[tid] += 1
      posters_name[tid] = tname
      monthly_users[post_time[0..6]].push(tid)
      # output actions
      file_actions.puts "#{post_time}\t#{tid}\t#{page_id}\tlike"
    }
  }
  puts "INFO: #{likes_count} likes are processed"

  file_actions.close

  File.open("./tmp/#{page_id}_users.txt", 'w+') { |f|
    f.puts "##{posters_name.size} users"
    f.puts "##{comments_count} comments from #{posters_clist.size} users"
    f.puts "##{likes_count} likes from #{posters_llist.size} users"
    f.puts "#user_id \tcomments \tlikes \tname"
    posters_name.each { |k,v| # k is user_id, v is user_name
      f.puts "#{k} \t#{posters_clist[k]} \t#{posters_llist[k]} \t\#\"#{v}\""
    }
  }
  puts "INFO: #{posters_name.size} users are logged"

  File.open("./tmp/#{page_id}_daily.txt", 'w+') { |f|
    f.puts "#date \ttotal \tcomments \tlikes"
    daily_total.sort.each { |k,v|
      f.puts "#{k.to_s} \t#{v} \t#{daily_comments[k]} \t#{daily_likes[k]}"
      #process monthly records
      monthly_comments[k[0..6]] += daily_comments[k]
      monthly_likes[k[0..6]] += daily_likes[k]
      monthly_total[k[0..6]] += daily_total[k]
    }
  }

  File.open("./tmp/#{page_id}_monthly.txt", 'w+') { |f|
    f.puts "#date \tactive_users \ttotal \tcomments \tlikes"
    monthly_total.sort.each { |k,v|
      f.puts "#{k.to_s} \t#{monthly_users[k].uniq.size} \t#{v} \t#{monthly_comments[k]} \t#{monthly_likes[k]}"
    }
  }

  File.open("./tmp/actions_log.txt", 'a') { |f|
    f.puts "#{page_id}\t#{comments_count}\t#{likes_count}\t#{posters_name.size}"
  }
end

def dump_users_action(myfb)
  pages = myfb.db_read_pages
  pages.each_with_index { |e,i|
    next if i < 93 
    puts "[#{i}]\t#{e['_id']} \t#{e['doc']['username']}  \t#{e['doc']['likes']} \t##{e['doc']['name']}"
    page_id = e['_id']
    output_users(myfb, page_id)
  }
  puts "Total #{pages.size} pages"

end

=begin
regexp = /聰明機魔鏡大頭貼：(.*店)/
  find_target = {'page_id' => '188539001185548'}
  File.open('tmp/kobayashi/kobapics.txt', 'w+') { |file|
    pcoll.find(find_target, find_opts).each{ |item|
      #data = Hash.new(0)
      time = item['doc']['created_time']
      msg = item['doc']['message']
      next if msg.nil?
      m = regexp.match(msg)
      next if m.nil?
      t = Time.parse(time).strftime('%Y-%m')
      file.print t, "\t", m[1], "\n"
    }
  }
=end
