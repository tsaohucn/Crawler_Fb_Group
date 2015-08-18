#require './fb_page_crawler'
#require './config/fb_config'
require './config/db_ro_config'
require 'time'
require 'rubygems'
require 'json'
require 'bson'
require 'mongo'
#require './test_functions'

$output_path = './tmp/hubert/'

PAGES = ['mcdonalds.tw','kfctaiwan','mosburger.tw','PizzaHut.TW','BurgerKingTW']

#101615286547831 mcdonalds.tw 台灣麥當勞官方粉絲團
#324273577645211 kfctaiwan 肯德基 KFC Taiwan 非吃不可粉絲團
#259676855661 mosburger.tw MOS Burger 摩斯漢堡「癮迷」俱樂部
#263705449348 PizzaHut.TW 必勝客 Pizza Hut Taiwan
#363470173013 BurgerKingTW BurgerKing 漢堡王火烤美味分享團

def dump_posts(mongo_db, page_id, date_start, date_end)
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  find_target = {'page_id' => page_id, 'post_time' => { '$gt' => date_start, '$lt' => date_end}}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'page_id' => 1, 
            'doc.type' => 1, 'doc.shares.count' => 1, 'doc.likes.count' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  post_count = 0
  monthly_posts = Hash.new(0)
  users_hash = Hash.new{ |h,k| h[k] = Hash.new(0) }

  convert_time = lambda { |t| t.strftime("%Y-%m-%d")}

  puts "Processing page #{page_id} ..."
  file_output_comments = File.open($output_path + "#{page_id}_comments.txt", 'w+')
  file_output_comments.puts ['#comment_id', 'user_fb_id', 'page_id', 'post_id', 'likes_on_comments', 'created_time', 'latest_obtain_date_by_itri'].join("\t")
  File.open($output_path + "#{page_id}_posts.txt", 'w+') { |file|
    data_output = ['#post_id', 'post_time', 'type', 'shares', 'comments', 'likes_on_comments', 'likes', 'real_likes', 'latest_obtain_date_by_itri', 'has_message?']
    file.puts data_output.join("\t")
    pcoll.find(find_target,{}).sort('post_time').each{ |post|
      post_count += 1
      data_output.clear
      data_output << post['_id']
      data_output << post['post_time']
      post_date = convert_time.call(post['post_time']) # convert time to date
      monthly_posts[post_date[0..6]] += 1

      # type
      post_type = 'unknown'
      post_type = post['doc']['type'] if post.has_key?('doc') && post['doc'].has_key?('type')
      data_output << post_type

      # shares
      share_count = 0
      share_count = post['doc']['shares']['count'].to_i if post.has_key?('doc') && post['doc'].has_key?('shares')
      data_output << share_count

      # comments
      comment_count = 0
      likes_on_comments = 0
      db_comment = ccoll.find_one({'_id' => post['_id']}, {:fields => {'count' => 1, 'doc' => 1}}) # find the post comments
      comment_count = post['doc']['comments']['data'].size if post['doc'].has_key?('comments')
      unless db_comment.nil?
        comment_count = db_comment['count'] if db_comment['count'] > comment_count
        db_comment['doc'].each { |e|
          likes_on_comments += e['like_count'].to_i
          comment_output = [e['id'],e['from']['id'], post['page_id'], post['_id'], e['like_count'].to_i, e['created_time'], post['last_updated']]
          file_output_comments.puts comment_output.join("\t")
          users_hash[e['from']['id']][:comments] += 1
          users_hash[e['from']['id']][:likes_on_comments] += e['like_count'].to_i
        }
      end
      data_output << comment_count
      data_output << likes_on_comments
      
      # likes
      like_count = 0
      db_like = lcoll.find_one({'_id' => post['_id']}, {:fields => {'count' => 1}}) # find the post likes
      like_count = db_like['count'] unless db_like.nil?
      data_output << like_count

      # real_likes
      real_like_count = 0
      real_like_count = post['doc']['likes']['count'].to_i if post.has_key?('doc') && post['doc'].has_key?('likes')
      data_output << real_like_count

      data_output << post['last_updated']
      data_output << (post['doc']['message'].nil? ? 'NO' : 'YES')
      file.puts data_output.join("\t")
    }
  }
  file_output_comments.close

  File.open($output_path + "#{page_id}_user_comments.txt", 'w+') { |file|
    file.puts "#user_id\tcomments\tlikes_on_comments\taverage_likes_per_comment"
    users_hash.sort_by { |k,v| -v[:likes_on_comments]}.each { |k,v|
      file.puts "#{k}\t#{v[:comments]}\t#{v[:likes_on_comments]}\t#{v[:likes_on_comments].to_f / v[:comments]}"
    }
  }

  File.open($output_path + "#{page_id}_monthly_posts.txt", 'w+') { |file|
    monthly_posts.each { |k,v|
      file.puts "#{k}\t#{v}"
    }
  }
  puts "#{post_count} posts of page '#{page_id}' have been processed."

end

def main
  include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD, MONGODB_DBNAME)
  mongo_db = client[MONGODB_DBNAME]

  #pcoll = myfb.mongo_db[TABLE_POSTS]
  #ccoll = myfb.mongo_db[TABLE_COMMENTS]
  #lcoll = myfb.mongo_db[TABLE_LIKES]

  #page_ids = ['101615286547831','324273577645211','259676855661','263705449348','363470173013']
  page_ids = ['101615286547831','324273577645211','363470173013']

  date_start = Time.new(2013,6,1)
  date_end = Time.new(2013,8,1)

  page_ids.each { |page_id|
    dump_posts(mongo_db, page_id, date_start, date_end)
  }
end #main

# Main Process begins
begin
  time_start = Time.now
  puts "Start: #{time_start}"
  puts "========================================"
  main
rescue => ex
  $stderr.puts ex.message
  $stderr.puts ex.backtrace.join("\n")
ensure
  time_end = Time.now
  puts "========================================"
  puts "End: #{time_end}"
  time_cost = time_end - time_start
  puts "Time cost: #{time_cost} seconds"
  puts "Time cost: #{Time.at(time_cost).gmtime.strftime('%R:%S')}"
end
