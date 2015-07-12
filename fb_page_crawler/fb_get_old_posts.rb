class FbPageCrawler
  # Retrieve older posts from oldest_time
  # return a array of post hashes
  # oldest_time must be an unix time stamp
  # oldest_time should be the oldest posts that has been obtained in past
  def fb_get_old_posts(page_id, oldest_time, opts={}, &block)
    #oldest_time - 1 because facebook until will include the time point
    find_opts = {:until => oldest_time - 1}.merge opts
    fb_get_posts(page_id, find_opts, &block)
  end
end

