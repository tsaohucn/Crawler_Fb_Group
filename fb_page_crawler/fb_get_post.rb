class FbPageCrawler
  # Return a array of post hash by a post_id
  # post hash: id, from{id, name}, message, shares{count}, likes{data,count}, created_time
  def fb_get_post(post_id)
    raise 'post_id can not be empty' if post_id.nil? || post_id.empty?
    query = "/#{post_id}?"
    query << "fields=id,message,created_time,updated_time,from,status_type,type,shares,likes.summary(true),comments.summary(true)" if @apply_fields
    # A valid access_token is required
    query << "&access_token=#{@access_token}"

    data = fb_graph_get(query)
    #puts data
    raise 'No available data retrieved' if data.nil? || data.empty?
    data = JSON.parse(data)
    raise 'No available data retrieved' if data.nil? || data.empty?
    data
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
    # Return a empty hash
    {}
  end
end
