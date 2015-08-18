#require './fb_page_crawler'
#require './config/fb_config'
require './config/db_ro_config'
require 'time'
require 'rubygems'
require 'json'
require 'bson'
require 'mongo'
#require './test_functions'

def main
  include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD, MONGODB_DBNAME)
  mongo_db = client[MONGODB_DBNAME]

  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  regexp = /聰明機魔鏡大頭貼：(.*店)/
  find_target = {'page_id' => '188539001185548'}
  File.open('tmp/kobayashi/kobapics.txt', 'w+') { |file|
    pcoll.find(find_target, find_opts).each{ |item|
      #data = Hash.new(0)
      time = item['doc']['created_time']
      msg = item['doc']['message']
      next if msg.nil?
      m = regexp.match(msg)
      next if m.nil?
      t = Time.parse(time).strftime('%Y-%m')
      file.print t, "\t", m[1], "\n"
    }
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
