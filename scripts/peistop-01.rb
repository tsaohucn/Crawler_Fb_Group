#require './fb_page_crawler'
#require './config/fb_config'
require './config/db_ro_config'
require 'time'
require 'rubygems'
require 'json'
require 'bson'
require 'mongo'
#require './test_functions'

$output_path = './tmp/peistop/'

#101615286547831 mcdonalds.tw 台灣麥當勞官方粉絲團
#324273577645211 kfctaiwan 肯德基 KFC Taiwan 非吃不可粉絲團
#259676855661 mosburger.tw MOS Burger 摩斯漢堡「癮迷」俱樂部
#263705449348 PizzaHut.TW 必勝客 Pizza Hut Taiwan
#169166689767336 pec21c 21 Century 風味館
#115361891807579 Dominos.tw 達美樂 Domino's Pizza Taiwan
#363470173013 BurgerKingTW BurgerKing 漢堡王火烤美味分享團
#119109161438728  爭鮮
#267009673341918 tw.yoshinoya 吉野家‧發現幸福

def output_comments(mongo_db,page_id)
  find_target = {'page_id' => page_id}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  report = Hash.new
  post_count = 0
  comt_count = 0
  post_withc = 0
  puts "Processing page #{page_id} ..."
  File.open($output_path + "#{page_id}.txt", 'w+') { |file|
    f_fields = ['fb_post_id', 'fb_comment_id', 'fb_user_id', 'created_time(timestamp)', 'created_time(iso8601)', 'message']
    file << '#'
    file.puts f_fields.join("\t")
    posts = pcoll.find(find_target, find_opts).each{ |post|
      next if post['doc'].has_key?('error')
      #next if post['doc']['message'].nil?
      post_count += 1
      # write posts info into file
      #p post unless post.has_key?('doc')
      #p post unless post['doc'].has_key?('from')
      output_data = []
      output_data << post['_id'] << post['_id'] << post['doc']['from']['id']
      #output_data << Time.parse(post['doc']['created_time'].to_s).to_i
      tmp_time = Time.parse(post['doc']['created_time'].to_s)
      output_data << tmp_time.to_i
      output_data << tmp_time.iso8601
      #output_data << ((post['doc'].has_key?('likes') and post['doc']['likes'].has_key?('count'))?(post['doc']['likes']['count'].to_i):(0))
      tmp_msg = post['doc']['message'].to_s.gsub(/\s/, ' ')
      tmp_msg = post['doc']['story'].to_s.gsub(/\s/, ' ') if post['doc']['message'].nil?
      #output_data << post['doc']['type']
      output_data << tmp_msg
      file.puts output_data.join("\t").to_s
      # find all comments for the post
      ccoll.find({'_id' => post['_id']}, find_opts).each { |pcomt|
        comt_count += pcomt['doc'].size
        post_withc += 1 if pcomt['doc'].size > 0
        pcomt['doc'].each{ |e|
          output_data = []
          output_data << post['_id'] << e['id'] << e['from']['id']
          tmp_time = Time.parse(e['created_time'].to_s)
          output_data << tmp_time.to_i
          output_data << tmp_time.iso8601
          #output_data << e['like_count'].to_i
          output_data << e['message'].to_s.gsub(/\s/, ' ')
          file.puts output_data.join("\t").to_s
        }
      }

    }
    puts "Page(#{page_id}): #{comt_count} comments in #{post_withc} posts over total #{post_count} posts"
  }
  report = {page_id: page_id, post_count: post_count, comment_count: comt_count, post_has_comment: post_withc}
end

def main
  include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD, MONGODB_DBNAME)
  mongo_db = client[MONGODB_DBNAME]

  page_ids = ['101615286547831','324273577645211','259676855661','263705449348',
              '169166689767336','115361891807579','363470173013','119109161438728','267009673341918']

  #page_ids = ['162737870484034']

  page_ids.each { |page_id|
    #dump_posts(mongo_db, page_id)
    p output_comments(mongo_db, page_id)
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
