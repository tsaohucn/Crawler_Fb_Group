class FbPageCrawler
  # Add old posts into databse via page_id
  # page_id should be the number id, not username id
  # oldest_time should be Time object
  def db_add_old_feeds(group_id,group_name, oldest_time, opts={})
    now_1 = Time.now
    puts "\"#{group_name}\" : 進行社團舊文章增加..."
    raise 'group_id can not be empty' if group_id.nil? || group_id.empty?
    time_update = Time.now
    # Retrieve new posts from the target page
    group_feeds = fb_get_old_feeds(group_id, oldest_time, {:limit => 300}.merge(opts))
    oldest_feed_time = group_feeds.empty? ? oldest_time : Time.parse(group_feeds.last.fetch('created_time'))
    oldest_feed_time = oldest_time if oldest_time < oldest_feed_time

    # update page data in mongo databse
    coll = @mongo_db[TABLE_GROUPS]
    update_content = {'oldest_feed_time' => oldest_feed_time, 'last_updated' => time_update}
    update_content['check_old_feeds'] = false if group_feeds.empty? # don't check old posts again if no old posts retrieved
    coll.update({'_id' => group_id}, 
                {'$set' => update_content})

    # write posts data into mongo database if any post retrieved
    # REVIEW: the posts will be lost if page_update fails
    coll = @mongo_db[TABLE_FEEDS]
    group_feeds.each { |feed|
      #post = {"shares" : {"count" : 0}}.merge(post)
      #post['likes'].delete("paging")
      #post['comments'].delete("paging")
      feed_data = {'_id' => feed['id'],
                   'group_id' => group_id,
                   'feed_time' => Time.parse(feed['created_time']),
                   #'last_updated' => time_update,
                   'last_updated' => Time.at(1000), # set a small value so that it will be updated quickly
                   'doc' => feed}
      #coll.insert(post_data)
      db_insert_data(coll, feed_data)
      #res = coll.update({'_id' => post['id']}, post_data)
      #coll.insert(post_data) if res.has_key?('updatedExisting') && res['updatedExisting'] == false
      #@@logger.debug "db_add_old_posts: post_id=#{post['id']} response:#{res.inspect}"

      # update comments
      #db_update_post_comments(post['id'])
      # update likes
      #db_update_post_likes(post['id'])
    }
    now_2 = Time.now
    $stderr.puts "\"#{group_name}\" : 完成社團舊文章增加[#{group_feeds.size}篇][耗時#{now_2 - now_1}秒]"
    return now_2 - now_1

  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
  end
end
