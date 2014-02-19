#!/usr/bin/ruby

require 'yaml'
require 'csv'
%w(rubygems wordnik).each {|lib| require lib}
#require 'rubypython'

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require "evernote.rb"
require "kindle.rb"

IMPORT_FILE = "import.csv"

Wordnik.configure do |config|
  config.api_key = '<API-Key>'
  config.logger = Logger.new('/dev/null')
end

kindleClient = KindleWords::Client.new
evernoteClient = EvernoteWords::Client.new

words = kindleClient.getWords + evernoteClient.getWords

# Load the file.
saved_words = YAML.load_stream(File.open('saved_words.yaml'))

# Add a new key-value pair to the root of the first document.
if saved_words.empty? || saved_words[0].nil?
  saved_words[0] = []
end
# name -> def
ws = saved_words[0].map{|w| w[:front] }

def cleanup(s)
  s.downcase.gsub /[\s,.:'"()!?;]/, ''
end

words.map!{|w| w[:word] = cleanup(w[:word]); w}.uniq!

words.keep_if do |w|
  ! ws.include? w[:word]
end

new_defs = words.map do |w|
  next unless (defs = Wordnik.word.get_definitions(w[:word], :use_canonical => true)) && 
    !defs.empty?
  wdef = "Definitions:<br>"
  defs.each do |definition|
    wdef += " - " + definition['text'] + "<br>"
  end
  if ((examples = Wordnik.word.get_examples(w[:word])) && 
      (examples = examples['examples']) &&
      !examples.empty?)
    wdef += "<br>Examples:<br>"
    examples.each do |example|
      wdef += " - " + example['text'] + "<br>"
    end
  end
  if ((syns = Wordnik.word.get_related(w[:word], :type => 'synonym')) && 
      !syns.empty? &&
      (syns = syns[0]) &&
      !syns.empty? &&
      (syns = syns['words']) &&
      !syns.empty?) 
    wdef += "<br>Synonyms:<br>"
    wdef += " - " + syns.join(', ')
  end
  {:front => w[:word], :back => wdef, :tag => w[:tags].join(' ')}
end.compact

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

