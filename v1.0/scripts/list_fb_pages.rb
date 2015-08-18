#!/usr/bin/env ruby
#require 'bson'
require 'mongo'

include Mongo

#TABLE_TEST = 'test'
TABLE_TEST = 'pages'

HOST = '192.168.26.180'
PORT = 27017

DBNAME = 'fb_beta'
USRNAME = 'ob'
USRPW = 'star2474'

def main
	client = MongoClient.new(HOST, PORT)
	client.add_auth(DBNAME, USRNAME, USRPW, DBNAME)
	db = client[DBNAME]
	coll = db[TABLE_TEST]

	data = Hash.new
	time1 = Time.now
	cnt = 0
	item0 = nil
	coll.find().each { |item|
		cnt += 1
		puts "#{item['_id']} : #{item['doc']['username']}"
		puts "#{item['doc']['name']}"
		puts '-'*80
	}
	puts "#{cnt} pages"
end

main

