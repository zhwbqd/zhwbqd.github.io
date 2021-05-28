#!/usr/bin/ruby

require 'json'

list = JSON.parse(ARGV[0])
list.sort! { |a,b| b['subscribers'] <=> a['subscribers'] }

data = "---\nlayout: page\ntitle: Following\npermalink: /following/\n---\n"
data += "| Blogs | Feedly Subscribers |\n|:--- | ---:|\n"
list.each { |elem| data += "| [#{elem['title']}](#{elem['website']}) | #{elem['subscribers'].to_s.reverse.scan(/\d{3}|.+/).join(",").reverse} |\n"}

data += "\n#{Time.now}\n"

File.write("following.md", data)
