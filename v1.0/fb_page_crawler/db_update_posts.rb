class FbPageCrawler
  # Update some posts within database
  # :update_threshold indicates a threshold and only posts newer then it will be updated
  # :update_interval indicates an interval to avoid frequency facebook querying
  def db_update_posts(opts={})
    find_opts = {
      :newborn => false,
      :update_threshold => @update_threshold,
      :update_interval => @update_interval,
      :limit => 3,
      :sort => ['last_updated', :ascending], # use :ascending to retrieve outdated posts
      :fields => {'last_updated' => 1, 'page_id' => 1, 'post_time' => 1}
    }.merge opts # TODO: rewrite opts with ruby 2.0 features
	
	#puts "find_options=" << find_opts.to_s
	
    time_update = Time.now #get current time
	#get update threshold
    update_threshold = time_update - find_opts[:update_threshold]
	#delete update threshold options
    find_opts.delete(:update_threshold)
	#get update interval
    update_interval = time_update - find_opts[:update_interval]
	#delete update interval option
    find_opts.delete(:update_interval)
    if find_opts[:newborn]
      update_threshold = Time.at(0)
      update_interval = Time.at(1001)
    end
    find_opts.delete(:newborn) # Update new appended data

    # update page data in mongo databse
    #coll = @mongo_db[TABLE_PAGES]
    #coll.update({'_id' => page_id}, 
    #            {'$set' => {'last_updated' => time_update}})

    # only post that was created newer than update_threshold will be updated
    time_1 = Time.now
    find_target = {'post_time' => {'$gt' => update_threshold},
                   'last_updated' => {'$lt' => update_interval}}
    coll = @mongo_db[TABLE_POSTS]
    posts = coll.find(find_target, find_opts).to_a
    time_2 = Time.now
    #$stderr.puts "db_update_posts: updating #{posts.size} posts" if posts.size > 0
    posts.each { |post|
      $stderr.puts "db_update_post:updating post(#{post['_id']}):post_time=#{post['post_time']}last_updated=#{post['last_updated']}"
      new_post = fb_get_post(post['_id'])
      #post = {"shares" => {"count" => 0}}.merge(post)
      #new_post['likes'].delete("paging")
      #new_post['comments'].delete("paging")
      #puts new_post
      if new_post.empty?
        coll.update({'_id' => post['_id']}, 
                    {'$set'=> {'last_updated' => time_update}}
				   )
        next
      end

      # update comments  
      #db_update_post_comments(post['_id']) if new_post.has_key?('comments')
      # update likes
      #db_update_post_likes(post['_id']) if new_post.has_key?('likes')
      # update the post
      #coll.update({'_id' => post['_id']}, 
        #          {'$set' => {'last_updated' => time_update, 'doc' => new_post}})
    }

    #$stderr.puts "db_update_posts: #{posts.size} posts are updated" if posts.size > 0
    posts.size
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
  end
end
