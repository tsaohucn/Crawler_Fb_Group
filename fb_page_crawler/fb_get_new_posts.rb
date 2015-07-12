class FbPageCrawler
  # An alias of fb_get_posts_since
  # Retrieve posts from now to last_time
  # return a array of post hashes
  # latest_time must be an unix time stamp
  # latest_time should be the latest posts that has been obtained in past
  def fb_get_new_posts(page_id, latest_time, opts={}, &block)
    find_opts = {:since => latest_time}.merge opts
    fb_get_posts_since(page_id, latest_time, find_opts, &block)
  end
end

