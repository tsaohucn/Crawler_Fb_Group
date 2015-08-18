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
$output_path = './tmp/pushme/data_dump/'

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

def dump_users(mongo_db, page_id)
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  find_target = {'page_id' => page_id}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'page_id' => 1, 
            'doc' => 1}
  find_opts = {:fields => fields}

  puts "Processing page #{page_id} ..."
  users = {}

  # comments
  ccoll.find(find_target, find_opts).each { |post|
    post['doc'].each { |e|
      tmp_id = e['from']['id']
      tmp_name = e['from']['name']
      users[tmp_id] = tmp_name
    }
  }

  #likes
  lcoll.find(find_target, find_opts).each { |post|
    post['doc'].each { |e|
      tmp_id = e['id']
      tmp_name = e['name']
      users[tmp_id] = tmp_name
    }
  }

  puts "Retrieve #{users.size} users"
  File.open($output_path + "#{page_id}_users.txt", 'w+') { |file|
    users.each { |k,v|
      file.puts "#{k}\t#{v}"
    }
  }
  users
end

def dump_data(mongo_db, page_ids)
  page_coll = mongo_db[TABLE_PAGES]
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  page_name = Hash.new('')
  page_doc = Hash.new

  comments_by_user = Hash.new(0)
  likes_by_user = Hash.new(0)

  posts_by_page = Hash.new(0)
  comments_by_page = Hash.new(0)
  likes_by_page = Hash.new(0)

  whole_users = Hash.new
  users_by_page = Hash.new { |h,k| h[k] = Hash.new }

  # process each page detail data
  page_ids.each_with_index { |page_id,i|
    find_target = {'page_id' => page_id}
    #fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'page_id' => 1, 
    #          'doc' => 1}
    #find_opts = {:fields => fields}

    printf '[%2d/%2d] ', i+1, page_ids.size;
    puts "Processing page #{page_id} ..."

    # check pages
    find_opts = {:fields => {'doc' => 1}}
    page_coll.find({'_id' => page_id}, find_opts).each { |page|
      page_name[page_id] = page['doc']['name'] if page['doc'].has_key?('name')
      page_doc[page_id] = page['doc']
    }

    # check posts
    find_opts = {:fields => {'doc' => 1}}
    pcoll.find(find_target, find_opts).each { |post|
      posts_by_page[page_id] += 1
    }

    # check comments
    find_opts = {:fields => {'count' => 1, 'doc' => 1}}
    ccoll.find(find_target, find_opts).each { |post|
      comments_by_page[page_id] += post['count']
      # read comment users
      post['doc'].each { |e|
        tmp_id = e['from']['id']
        tmp_name = e['from']['name']
        users_by_page[page_id][tmp_id] = tmp_name
        whole_users[tmp_id] = tmp_name
        comments_by_user[tmp_id] += 1
      }
    }

    # check likes
    find_opts = {:fields => {'count' => 1, 'doc' => 1}}
    lcoll.find(find_target, find_opts).each { |post|
      likes_by_page[page_id] += post['count']
      # read like users
      post['doc'].each { |e|
        tmp_id = e['id']
        tmp_name = e['name']
        users_by_page[page_id][tmp_id] = tmp_name
        whole_users[tmp_id] = tmp_name
        likes_by_user[tmp_id] += 1
      }
    }

  }

  File.open($output_path + 'pushme_fb_stores.txt', 'w+') { |file|
    file.puts "\##{ page_ids.size } stores"
    file.puts "\##{ whole_users.size } users"
    file.puts "\##{ posts_by_page.inject(0) { |s,h| s + h[1]} } posts"
    file.puts "\##{ comments_by_page.inject(0) { |s,h| s + h[1]} } comments"
    file.puts "\##{ likes_by_page.inject(0) { |s,h| s + h[1]} } likes"
    output_data = ['#page_id', 'page_likes', 'talking_about_count', 'posts', 'comments', 'likes', 'users', 'page_name']
    file.puts output_data.join("\t")
    page_ids.each{ |page_id|
      output_data = [page_id, page_doc[page_id]['likes'].to_i, page_doc[page_id]['talking_about_count'].to_i,
                     posts_by_page[page_id], comments_by_page[page_id], likes_by_page[page_id], 
                     users_by_page[page_id].size, page_name[page_id]]
      file.puts output_data.join("\t")  
    }
  }

  File.open($output_path + 'pushme_fb_users.txt', 'w+') { |file|
    file.puts "\##{ whole_users.size } users"
    output_data = ['#fb_id', 'comments', 'likes', 'name']
    file.puts output_data.join("\t")
    whole_users.each { |k,v|
      output_data = [k, comments_by_user[k], likes_by_user[k], v]
      file.puts output_data.join("\t")
    }
  }

  puts "#{ page_ids.size } stores"
  puts "#{ whole_users.size } users"
  puts "#{ posts_by_page.inject(0) { |s,h| s + h[1]} } posts"
  puts "#{ comments_by_page.inject(0) { |s,h| s + h[1]} } comments"
  puts "#{ likes_by_page.inject(0) { |s,h| s + h[1]} } likes"

end

def main
  include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD, MONGODB_DBNAME)
  mongo_db = client[MONGODB_DBNAME]

  coll = mongo_db[TABLE_PAGES]
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  #page_ids = ['101615286547831','324273577645211','259676855661','263705449348','363470173013']

  find_target = {'page_id' => '259676855661'}
  find_target = {}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  # retrieve pushme stores from the file
  file_name = 'pages_pushme.txt'
  pages = read_pages(file_name)
  puts "Read #{pages.size} records from #{file_name}"

  # confirm the facebook id for the pushme stores
  page_ids = get_pageids(mongo_db, pages)
  puts "Read #{page_ids.size} records of pushme stores"

  unless Dir.exists?($output_path)
    puts "Creating #{$output_path}"
    Dir.mkdir($output_path)
  end

  #p page_ids
  dump_data(mongo_db, page_ids)
  #dump_data(mongo_db, ['448442665197068','453295671370774'])

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
