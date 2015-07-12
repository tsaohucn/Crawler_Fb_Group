#require './fb_page_crawler'
#require './config/fb_config'
require './config/db_ro_config'
require 'time'
require 'rubygems'
require 'json'
require 'bson'
require 'mongo'
#require 'tiny_tds'
require 'csv'
#require "active_record"
#require './test_functions'

$output_path = './tmp/tosql/'

#101615286547831 mcdonalds.tw 台灣麥當勞官方粉絲團
#324273577645211 kfctaiwan 肯德基 KFC Taiwan 非吃不可粉絲團
#259676855661 mosburger.tw MOS Burger 摩斯漢堡「癮迷」俱樂部
#263705449348 PizzaHut.TW 必勝客 Pizza Hut Taiwan
#169166689767336 pec21c 21 Century 風味館
#115361891807579 Dominos.tw 達美樂 Domino's Pizza Taiwan
#363470173013 BurgerKingTW BurgerKing 漢堡王火烤美味分享團
#119109161438728  爭鮮
#267009673341918 tw.yoshinoya 吉野家‧發現幸福

=begin
ActiveRecord::Base.establish_connection(
  :adapter => "sqlserver",
  :host => "211.20.109.48",
  :database => "fb_test",
  :username => "yuyu",
  :password => "iscae"
) 

class FooBar < ActiveRecord::Base
  self.table_name = "fb_comments"
end
=end

def output_sql_comments(mongo_db,page_ids)
  #pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  #lcoll = mongo_db[TABLE_LIKES]

  #CSV.open($output_path + "sql_comments.csv", 'w+') { |csv|
  File.open($output_path + "sql_comments.txt", 'w+') { |file|
    page_ids.each { |page_id|
      find_target = {'page_id' => page_id}
      fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
      #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
      find_opts = {:fields => fields}

      puts "Processing page #{page_id} ..."
      ccoll.find({'page_id' => page_id}, find_opts).each { |pcomt|
        pcomt['doc'].each{ |e|
          output_data = []
          output_data << e['id'] << page_id << pcomt['_id'] << e['from']['id'] << e['from']['name']
          output_data << e['message'].to_s.gsub(/\s/, ' ')
          tmp_time = Time.parse(e['created_time'].to_s)
          output_data << tmp_time.utc.iso8601
          output_data << e['like_count'].to_i
          file.puts output_data.join("\t").to_s
          #csv << output_data
        }
      }
    }
  }
  
end

def main
  include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD, MONGODB_DBNAME)
  mongo_db = client[MONGODB_DBNAME]

  unless Dir.exists?($output_path)
    puts "Creating #{$output_path}"
    Dir.mkdir($output_path)
  end

  page_ids = ['101615286547831','324273577645211','259676855661','263705449348',
              '169166689767336','115361891807579','363470173013','119109161438728','267009673341918']

  page_ids = ['267009673341918']

  output_sql_comments(mongo_db, page_ids)

  #sql_client = TinyTds::Client.new(:username => 'yuyu', :password => 'iscae', :host => '211.20.109.48', :database => 'fb_test')
  #result = sql_client.execute("select top 10 * from fb_comments");
  #result.each do |row|
  #  puts row
  #end

  #FooBar.find_each(:batch_size => 100) do |foo|
  #  p foo
    #@coll.insert({'col1' => "#{foo.bar1}", "col2" => "#{foo.bar2}", "col3" => "#{foo.bar3}"});
  #end

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
