class FbPageCrawler
  # Obtain some pages from database
  def db_obtain_groups(opts={})
    find_opts = {
      :update_interval => @update_interval,
      :limit => 1,
      :sort => ['last_updated', :ascending], # use :ascending to retrieve outdated posts
      :fields => {'last_updated' => 1, 'latest_feed_time' => 1, 'oldest_feed_time' => 1, 'doc.name' => 1, 'check_new_feeds' => 1, 'check_old_feeds' => 1}
    }.merge opts # TODO: rewrite opts with ruby 2.0 features
    
	time_update = Time.now
    update_interval = time_update - find_opts[:update_interval]
    find_opts.delete(:update_interval)
    find_target = {'last_updated' => {'$lt' => update_interval}, 'check_new_feeds' => true}

    coll = @mongo_db[TABLE_GROUPS]
    coll.find(find_target, find_opts).to_a
  end
end
