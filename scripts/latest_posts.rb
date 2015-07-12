#!/usr/bin/env ruby
# This script prints the latest posts from a specified FB page
require 'bson'
require 'mongo'

include Mongo

TABLE_TEST = 'posts'
HOST = '192.168.26.180'
PORT = 27017
DBNAME = 'fb_beta'
USRNAME = 'ob'
USRPW = 'star2474'

TARGET = '135084993203916'
POST_LIMIT = 10

def list_latest_posts(target, limit = POST_LIMIT)
	client = MongoClient.new(HOST, PORT)
	client.add_auth(DBNAME, USRNAME, USRPW, DBNAME)
	db = client[DBNAME]
	coll = db[TABLE_TEST]

	data = Hash.new
	time1 = Time.now
	cnt = 0
	target = {'page_id' => target}
	opts = {:sort => ['post_time', -1]}
	coll.find(target, opts).limit(POST_LIMIT).each { |item|
		cnt += 1
		#p item
		puts item['_id'] + ": " + item['post_time'].to_s
		puts item['doc']['message'].to_s + item['doc']['story'].to_s
		puts '-' * 80
	}

	puts "#{cnt} records"
end

def main
	ARGV.each { |page|
		puts "Looking up page #{page}"
		list_latest_posts(page)
	}
	list_latest_posts(TARGET) if ARGV.size == 0
	puts "Usage: #{$0} <page_id>" if ARGV.size == 0
end

main

