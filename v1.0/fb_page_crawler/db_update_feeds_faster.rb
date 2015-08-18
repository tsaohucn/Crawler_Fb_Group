class FbPageCrawler

  def db_update_feeds_faster(group_id,group_name,opts={})
###################grap old posts########################
    puts "=================\"#{group_name}\"================="
    now_1 = Time.now #test programin time
    find_opts = {
      #:update_interval => @update_interval,
      :sort => ['feed_time', :descending], # use :ascending to retrieve outdated posts
      :fields => {'doc' => 1},
      :limit => 200
    }.merge opts # TODO: rewrite opts with ruby 2.0 features
    #update_interval = now_1 - find_opts[:update_interval]
    find_target = {"group_id"=>group_id}#'last_updated' => {'$lt' => update_interval}}
    coll = @mongo_db[TABLE_FEEDS]
    old_feeds_set = coll.find(find_target, find_opts)
    #puts old_feeds_set.count
    old_feeds = old_feeds_set.to_a ###error
    now_2 = Time.now#test programin time
    old_feeds_oldest_time = old_feeds.last['doc'].fetch('created_time')
    old_feeds_latest_time = old_feeds.first['doc'].fetch('created_time')
    puts "\"#{group_name}\" : 進行社團舊文章抓取...#{old_feeds.size}篇[舊文章時間#{old_feeds_oldest_time}至#{old_feeds_latest_time}][耗時#{now_2 - now_1}秒]"#error
###################grap new posts########################
    new_feeds = Array.new(0)
    since_time = Time.parse(old_feeds_oldest_time) - 1
    until_time =  Time.parse(old_feeds_latest_time)
    puts "\"#{group_name}\" : 進行社團新文章抓取..."
    until until_time - 1 == since_time
      get_new_feeds = fb_get_feeds(group_id,{:limit => 20,:since=>since_time ,:until=>until_time})
      if !get_new_feeds.empty?
          new_feeds = new_feeds | get_new_feeds
          puts "\"#{group_name}\" : 抓到新文章...#{get_new_feeds.size}篇"#[#{since_time}到#{until_time}]
          #puts "抓取社團\"#{group_name}\"新文章...[文章時間從#{get_new_feeds.last.fetch('created_time')}到#{get_new_feeds.first.fetch('created_time')}]"
          until_time = Time.parse(get_new_feeds.last.fetch('created_time'))
      else
          #puts "\"#{group_name}\" : 回傳空&中斷抓取..."
          puts "Nothing...sleep 20"
          sleep 20
          #break
      end
    end
    #raise "\"#{group_name}\" : 沒抓到新聞章&中斷更新..." if new_feeds.size == 0
    now_3 = Time.now#test programin time
    if new_feeds.size == 0
      puts "\"#{group_name}\" : 完成社團新文章抓取...#{new_feeds.size}篇"
    else
      puts "\"#{group_name}\" : 完成社團新文章抓取...#{new_feeds.size}篇[新文章時間#{new_feeds.last.fetch('created_time')}至#{new_feeds.first.fetch('created_time')}][耗時#{now_3 - now_2}秒]"#error
    end

#######################process data########################
    arr = Array.new(0)
    old_feeds.each do |ele|
     arr << ele['doc']
    end
    #new_posts.each do |ele|
        #ele["likes"].delete("paging") if ele.has_key?["likes"]
        #ele["comments"].delete("paging") if ele.has_key?["comments"]
    #end
    change_feeds = new_feeds - arr
    now_4 = Time.now
    puts "\"#{group_name}\" : 須更新之文章...[#{change_feeds.size}篇]"#[耗時#{now_4 - now_3}秒]"
    count = 0
    change_feeds.each do |feed|
            result = coll.update({'_id' => feed['id']}, {'$set' => {'last_updated' => now_4,'doc' => feed}})
            count += result['n']
            #puts post['id'] if result['n'] == 0
    end
    now_5 = Time.now
    puts "\"#{group_name}\" : 進行社團資料庫文章更新...[#{count}篇][耗時#{now_5 - now_4}秒]"
    #puts "\"#{group_name}\" : 完成社團文章更新程式[#{count}篇][耗時#{now_5 - now_1}秒]"
    return now_5 - now_1
  rescue => ex
    #puts "\"#{group_name}\" : error on \"db_update_feeds_faster\"\n#{ex}"
    puts ex.backtrace.join("\n")
   # puts ex.backtrace.map{ |x|   
    # x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
   # [$1,$2,$4] 
#}
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
  end
end
