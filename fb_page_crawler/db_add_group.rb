class FbPageCrawler
  # Add a new page into databse via page_name or page_id
  def db_add_group(group_id,group_name)
    raise 'group_id can not be empty' if group_id.nil? || group_id.empty?
    time_update = Time.now
    group_data = fb_get_group(group_id)
    raise 'No available data retrieved' unless group_data.has_key?('id')
    # Check if the page is in database
    coll = @mongo_db[TABLE_GROUPS]
    raise "Group \"#{group_id}\" has been in the database" unless coll.find('_id' => group_data['id']).first.nil?
    # Retrieve some posts from the target page
    group_feeds = fb_get_feeds(group_id, :until => time_update.to_i, :limit => 3)
    latest_post_time = group_feeds.empty? ? time_update : Time.parse(group_feeds.first.fetch('created_time'))
    oldest_post_time = group_feeds.empty? ? time_update : Time.parse(group_feeds.last.fetch('created_time'))

    $stderr.puts "db_add_group: adding group \"#{group_name}\" : \"#{group_id}\" into the database"
    group_data = {'_id' => group_data['id'],
                 'latest_post_time' => latest_post_time,
                 'oldest_post_time' => oldest_post_time,
                 'last_updated' => time_update,
                 'check_new_posts' => true,
                 'check_old_posts' => true,
                 'doc' => group_data}
    #write page data into mongo databse
    coll.insert(group_data)
    #db_insert_data(coll, page_data)
    # REVIEW: some posts may get lost if posts inserting fails

    #write posts data into mongo database if any post retrieved
    coll = @mongo_db[TABLE_FEEDS]
    group_feeds.each { |feed|
      #post = {"shares" : {"count" : 0}}.merge(post)
      #post['likes'].delete("paging")
      #post['comments'].delete("paging")
      feed_data = {'_id' => feed['id'],
                   'page_id' => group_data['_id'],
                   'post_time' => Time.parse(feed['created_time']),
                   'last_updated' => time_update,
                   #'last_updated' => Time.at(100), # set a small value so that it will be updated quickly
                   'doc' => feed}
      #coll.insert(post_data)
      db_insert_data(coll, feed_data)
      # update comments
      #db_update_post_comments(post['id'])
      # update likes
      #db_update_post_likes(post['id'])
    }

  #rescue => ex
  #  @@logger.error ex.message
 #   @@logger.debug ex.backtrace.join("\n")
  end
end
