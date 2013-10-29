#!/usr/bin/ruby

require 'kindle_highlights'
require 'yaml'
require 'net/http'
require 'xmlsimple'
%w(rubygems wordnik).each {|lib| require lib}

Wordnik.configure do |config|
      config.api_key = '<API-Key>'
end

passwords = File.open('.pw', 'r')
line = passwords.gets.chomp
passwords.close

# pass in your Amazon credentials. Loads your books (not highlights) on init, so might take a while                                                             
kindle = KindleHighlights::Client.new("<email>", line) 

ca = kindle.books.select {|k| kindle.books[k].include? "Cloud Atlas"}

# Get the key of the first book
book_hash = ca.first.first

highlights = kindle.highlights_for(book_hash)

# Load the file.
saved_words = YAML.load_stream(File.open('saved_words.yaml'))

puts saved_words.inspect
# Add a new key-value pair to the root of the first document.
if saved_words.empty? || saved_words[0].nil?
  saved_words[0] = []
end
# name -> def
ws = saved_words[0].map{|w| w[:name] }

def cleanup(s)
  s.downcase.gsub /[\s,.:]/, ''
end

highlights.map!{|h| cleanup(h['highlight'])}.uniq!

highlights.keep_if do |h|
  ! ws.include? h
end

new_defs = highlights.map do |name|
  wdef = "Definitions:\n"
  Wordnik.word.get_definitions(name).each do |definition|
    wdef += " - " + definition['text'] + "\n"
  end
  wdef += "\nExamples:\n"
  Wordnik.word.get_examples(name)['examples'].each do |example|
    wdef += " - " + example['text'] + "\n"
  end
  wdef += "\nSynonyms:\n"
  wdef += " - " + Wordnik.word.get_related(name, :type => 'synonym')[0]['words'].join(', ')
  puts wdef
  {:name => name, :def => wdef}
end

unless new_defs.empty?
  new_saved_words = saved_words[0] + new_defs
  File.open('saved_words.yaml', 'w') do |file|
    file.write(YAML.dump(new_saved_words))
  end
end

