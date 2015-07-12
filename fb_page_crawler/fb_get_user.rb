class FbPageCrawler
  # Acquire User data from a user_id
  # Return a hash of user datas: 'id', 'name', 'username', etc
  def fb_get_user user_id
    raise 'post_id can not be empty' if post_id.nil? || post_id.empty?
    query = "/#{user_id}"

    data = fb_graph_get(query)
    raise 'No available data retrieved' if data.nil? || data.empty?
    data = JSON.parse(data)
    raise 'No available data retrieved' if data.nil? || data.empty?
    data
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join('\n')
    # Return a empty hash
    {}	
  end
end

