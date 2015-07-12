require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'json'
require 'time'
require 'logger'

require 'rubygems'
require 'mongo'

class FbPageCrawler
  @@fb_graph_host = "graph.facebook.com"
  @@logger = nil
  include Mongo

  attr_accessor :logger
  attr_accessor :app_id, :app_secret, :access_token, :page_limit, :page_maxlimit
  attr_accessor :apply_fields, :update_threshold, :update_interval
  attr_accessor :mongo_db

  def initialize
    @app_id = ""
    @app_secret = ""
    @access_token = ""
    @group_limit = 400 # The max limit value could be 500 for facebook graph api
    @page_maxlimit = 10000
    @apply_fields = true # false indicates setting no fields in querying to retrieve all possible fields
    @update_threshold = 60 * 60 * 24 * 14 # a threshold and only posts newer then it will be updated(設越大張貼時間越久遠的文章也會更新到)
    @update_interval = 60 * 5 # an interval in seconds to avoid frequency facebook querying(設越大越不會頻繁更新才剛更新完的資料)
    @mongo_db = mongo_set_config()
    @@logger ||= Logger.new('log/fbpage.log', 'monthly')
    #@@logger ||= Logger.new(STDERR)
    @@logger.progname = 'FbPageCrawler'
    @@logger.level = Logger::WARN
    @@logger.level = Logger::DEBUG if DEBUG
  end
end

require './fb_page_crawler/fb_graph_get'
require './fb_page_crawler/fb_get_token'
require './fb_page_crawler/fb_get_user'
require './fb_page_crawler/fb_get_feeds'
require './fb_page_crawler/fb_get_posts_since'
require './fb_page_crawler/fb_get_new_posts'
require './fb_page_crawler/fb_get_old_posts'
require './fb_page_crawler/fb_get_post_likes'
require './fb_page_crawler/fb_get_post_comments'
require './fb_page_crawler/fb_get_post'
require './fb_page_crawler/fb_get_group'
require './fb_page_crawler/fb_is_numberid'

require './fb_page_crawler/mongo_set_config'
require './fb_page_crawler/db_add_group'
require './fb_page_crawler/db_add_new_posts'
require './fb_page_crawler/db_add_old_posts'
require './fb_page_crawler/db_obtain_pages'
require './fb_page_crawler/db_update_posts'
require './fb_page_crawler/db_update_posts_faster'
require './fb_page_crawler/db_update_post_comments'
require './fb_page_crawler/db_update_post_likes'
require './fb_page_crawler/db_insert_data'