require 'json'

file_name = 'pushme_users_by_store.txt'

store_list = Hash.new
a = Array.new
b = Hash.new { |h,k| h[k] = Hash.new(0) }

File.open(file_name, 'r').each { |line|
  #data = line.split
  json_data = JSON.parse line
  #json_data.each { |k,v| 
  #  store_id = k
  #  stores = v
  #}
  store_list.merge! json_data
  #b[store_id][] += data[2].to_i
}
#a.uniq!
#a.sort!
#p store_list

count = 0
store_list.each { |k,v|
  count += 1
  puts "[%d]Processing %s" % [count, k]
  a << k
  store_list.each { |k2,v2|
    b[k][k2] = (v & v2).size
  }
}

#puts "Writing %d users' data" % a.size
File.open('Result_stores.txt', 'w+'){ |file|
  file << "#store_id/store_id\t"
  file.puts a.join("\t")
  a.each { |id1|
    oData = [id1]
    a.each { |id2|
      oData << b[id1][id2]
    }
    file.puts oData.join("\t")
    #oData.clear
  }
}
