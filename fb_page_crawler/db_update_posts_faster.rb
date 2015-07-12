class FbPageCrawler

  def db_update_posts_faster(page_id,page_name,opts={})
###################grap old posts########################
    puts "\"#{page_name}\" : 進行粉絲團文章更新..."
    now_1 = Time.now #test programin time
    find_opts = {
      #:update_interval => @update_interval,
      :sort => ['post_time', :ascending], # use :ascending to retrieve outdated posts
      :fields => {'doc' => 1}
    }.merge opts # TODO: rewrite opts with ruby 2.0 features
    #update_interval = now_1 - find_opts[:update_interval]
    find_target = {"page_id"=>page_id}#'last_updated' => {'$lt' => update_interval}}
    coll = @mongo_db[TABLE_POSTS]
    old_posts = coll.find(find_target, find_opts).to_a
    now_2 = Time.now#test programin time
    puts "\"#{page_name}\" : 進行粉絲團舊文章抓取...[文章時間#{old_posts.first['doc'].fetch('created_time')}至#{old_posts.last['doc'].fetch('created_time')}][#{old_posts.size}篇][耗時#{now_2 - now_1}秒]"
###################grap new posts########################
    new_posts = Array.new(0)
    since_time = Time.parse(old_posts.first['doc'].fetch('created_time')) - 1
    until_time =  Time.parse(old_posts.last['doc'].fetch('created_time'))
    until until_time - 1 == since_time
      get_new_posts = fb_get_posts(page_id,{:limit => 200,:since=>since_time ,:until=>until_time})
      if !get_new_posts.empty?
      new_posts = new_posts | get_new_posts
      #puts "抓取粉絲團<#{page_name}>新文章<文章時間從#{get_new_posts.last.fetch('created_time')}到#{get_new_posts.first.fetch('created_time')}>"
      until_time = Time.parse(get_new_posts.last.fetch('created_time'))
      end
    end
    now_3 = Time.now#test programin time
    puts "\"#{page_name}\" : 進行粉絲團新文章抓取...[文章時間#{new_posts.last.fetch('created_time')}至#{new_posts.first.fetch('created_time')}][#{new_posts.size}篇][耗時#{now_3 - now_2}秒]"
    #$stderr.puts "db_update_posts: #{posts.size} posts are updated" if posts.size > 0
#######################process data########################
    arr = Array.new(0)
    old_posts.each do |ele|
     arr << ele['doc']
    end
    #new_posts.each do |ele|
        #ele["likes"].delete("paging") if ele.has_key?["likes"]
        #ele["comments"].delete("paging") if ele.has_key?["comments"]
    #end
    change_posts = new_posts - arr
    now_4 = Time.now
    puts "\"#{page_name}\" : 進行粉絲團需更新文章整理...[#{change_posts.size}篇][耗時#{now_4 - now_3}秒]"
    count = 0
    change_posts.each do |post|
            result = coll.update({'_id' => post['id']}, {'$set' => {'last_updated' => now_4,'doc' => post}})
            count += result['n']
            #puts post['id'] if result['n'] == 0
    end
    now_5 = Time.now
    puts "\"#{page_name}\" : 進行粉絲團資料庫文章更新...[#{count}篇][耗時#{now_5 - now_4}秒]"
    return now_5 - now_1
  #rescue => ex
   # @@logger.error ex.message
  #  @@logger.debug ex.backtrace.join("\n")
  end
end
