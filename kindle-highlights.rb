#!/usr/bin/ruby

require 'kindle_highlights'
require 'yaml'
require 'csv'
require 'net/http'
require 'xmlsimple'
%w(rubygems wordnik).each {|lib| require lib}
require 'rubypython'

IMPORT_FILE = "import.csv"

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

# Add a new key-value pair to the root of the first document.
if saved_words.empty? || saved_words[0].nil?
  saved_words[0] = []
end
# name -> def
ws = saved_words[0].map{|w| w[:front] }

def cleanup(s)
  s.downcase.gsub /[\s,.:]/, ''
end

highlights.map!{|h| cleanup(h['highlight'])}.uniq!

highlights.keep_if do |h|
  ! ws.include? h
end

new_defs = highlights.map do |name|
  wdef = "Definitions:<br>"
  Wordnik.word.get_definitions(name).each do |definition|
    wdef += " - " + definition['text'] + "<br>"
  end
  wdef += "<br>Examples:<br>"
  Wordnik.word.get_examples(name)['examples'].each do |example|
    wdef += " - " + example['text'] + "<br>"
  end
  wdef += "<br>Synonyms:<br>"
  wdef += " - " + Wordnik.word.get_related(name, :type => 'synonym')[0]['words'].join(', ')
  puts wdef
  {:front => name, :back => wdef, :tag => 'kindle cloud-atlas'}
end

begin
  CSV.open(IMPORT_FILE, 'wb', {:col_sep => "\t"}) do |csv|
    new_defs.each do |value|
      csv << value.values
    end
  end

  puts "Please manually open Anki select import csv from the Tools menu. Then close Anki and press ENTER to continue"
  STDIN.gets.chomp

  #RubyPython.start

  #sys = RubyPython.import("sys")
  #sys.path.append("/usr/share/anki")
  #sys.path.append("/usr/share/anki/anki")
  #p sys.version
  #p sys.path
  #Collection = RubyPython.import("Collection")
  #TextImporter = RubyPython.import("importing.TextImporter")
  #col = Collection("../Anki/User 1/collection.anki2")

  #p col.decks.rubify

  #cPickle = RubyPython.import("cPickle")
  #p cPickle.dumps("Testing RubyPython.").rubify

  #RubyPython.stop

ensure
  begin
    File.delete(IMPORT_FILE)
  rescue
  end
end
unless new_defs.empty?
  new_saved_words = saved_words[0] + new_defs
  File.open('saved_words.yaml', 'w') do |file|
    file.write(YAML.dump(new_saved_words))
  end
end

