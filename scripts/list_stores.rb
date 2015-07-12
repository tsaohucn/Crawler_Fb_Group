#require './fb_page_crawler'
#require './config/fb_config'
require './config/db_ro_config'
require 'time'
require 'rubygems'
require 'json'
require 'bson'
require 'mongo'
#require './test_functions'

$input_path = './scripts/'
$output_path = './tmp/list_stores/'

def is_numberic?(target_id)
  reg = /^\d+_?\d*$/
  reg.match(target_id)
end

def read_pages(pages_file)
  pages = []
  pages = File.open($input_path + pages_file, 'r').map { |page| page.strip }
  pages
end

def get_pageids(mongo_db, pages)
  page_ids = []
  pages.each { |page_name|
    if is_numberic?(page_name)
      page_ids << page_name
      #puts "page_id: #{page_name}"
      next
    end
    coll = mongo_db[TABLE_PAGES]
    find_target = {'doc.username' => page_name}
    find_opts = {:fields => {'doc.username' => 1}}
    tmp_id = coll.find_one(find_target,find_opts)['_id']
    page_ids << tmp_id
    #puts "page_id: #{tmp_id}\tpage_username: #{page_name}"
  }
  page_ids
end


def list_stores(mongo_db)
  page_coll = mongo_db[TABLE_PAGES]
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  File.open($output_path + "pagesinfo.txt", 'w+') { |file|
    f_line = []
    f_line << 'fb_page_id' << 'fb_hyperlink' << 'latest_post_time' << 'oldest_post_time' << 'fb_username' \
           << 'page_likes' << 'talking_about_count' << 'category' << 'site_name'
    file.puts f_line.join("\t") 
    page_coll.find({},{}).each{ |post|
      puts "Processing page #{post['_id']} : #{post['doc']['name']} ..."
      #file.puts post.to_json
      f_line.clear
      f_line << post['_id'] 
      if post['doc']['username'].nil?
        f_line << 'http://www.facebook.com/' + post['_id']
      elsif
        f_line << 'http://www.facebook.com/' + post['doc']['username'] 
      end
      f_line << post['latest_post_time'] << post['oldest_post_time']
      f_line << post['doc']['username']
      f_line << post['doc']['likes'] << post['doc']['talking_about_count']
      f_line << post['doc']['category'] << post['doc']['name']
      file.puts f_line.join("\t") 
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

  list_stores(mongo_db)

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
