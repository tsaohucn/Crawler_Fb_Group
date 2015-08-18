require 'json'

$input_path = './monthly/'
$compare_file = './fb_id.txt'

def read_pushme_users
  pushme_users = Array.new
  File.open($compare_file, 'r').each{ |line|
    pushme_users << line.chomp.strip
  }
  pushme_users.sort
end

def parse_page_id(file_name)
  regexp = /(\d+)\+\d{4}\-\d{2}/
  match = regexp.match(file_name)
  tid = nil
  tid = match[1] unless match.nil?
  tid
end

def read_file(file_name, target_users)
  page_id = parse_page_id(file_name)
  #user_comment = Hash.new(0)
  users = Array.new
  count = 0
  File.open($input_path + file_name, 'r').each { |line|
    data = JSON.parse line
    #user_comment[data['id']] += data['comments'] if data['comments'].to_i > 0
    tmp_id = target_users.bsearch { |x| x >= data['id'] }
    users << data['id'] if tmp_id == data['id']
    count += 1
  }
  #puts "%s: %d/%d" % [file_name,users.size,count]
  users
end

def read_users
  #raise 'No input_path'  unless Dir.exists?($input_path)
  dir = Dir.new($input_path)
  store_users = Hash.new { |h,k| h[k] = Array.new }
  files_count = 0
  pushme_users = read_pushme_users
  puts "Read %d fb users from pushme" % pushme_users.size
  dir.each { |iFile|
    next if iFile.match(/^\./)
    next unless iFile.match(/\.txt$/)
    page_id = parse_page_id(iFile)
    new_users = read_file(iFile, pushme_users)
    store_users[page_id].concat new_users
    files_count += 1
    puts "files_count: %d" % files_count if files_count % 500 == 0
    #break if new_users.size > 3
    #break if files_count >= 500
  }
  puts "Files: #{files_count} files on #{Dir.getwd}"

  store_users.each { |k,v|
    v.uniq!
    puts "%s has %d users" % [k,v.size]
  }

  File.open('pushme_users_by_store.txt', 'w+'){ |file|
    store_users.each{ |k,v|
      file.puts ({k => v}).to_json if v.size > 0
    }
  }

  user_relation = Hash.new { |h,k| h[k] = Hash.new(0) }
  store_users.each{ |k,v|
    v.each { |id1|
      v.each { |id2|
        user_relation[id1][id2] += 1
        user_relation[id2][id1] += 1
      }
    }
  }

  File.open('pushme_user_relation.txt', 'w+'){ |file|
    user_relation.each { |id1,v1|
      v1.each { |id2,v2|
        file.puts "%s\t%s\t%d" % [id1,id2,v2 / 2]
      }
    }
  }

end

def main
  read_users
end # main

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
