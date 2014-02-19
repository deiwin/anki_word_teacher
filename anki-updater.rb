#!/usr/bin/ruby

%w(rubygems wordnik yaml csv htmlentities progressbar).each {|lib| require lib}
#require 'rubypython'

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require "evernote.rb"
require "kindle.rb"

IMPORT_FILE = "import.csv"

Wordnik.configure do |config|
  config.api_key = '<API-Key>'
  config.logger = Logger.new('/dev/null')
end

clients = [KindleWords::Client.new, EvernoteWords::Client.new]

words = clients.reduce([]) do |memo, client|
  memo + client.getWords
end

# Load the file.
saved_words = YAML.load_stream(File.open('saved_words.yaml'))
@word_mappings = YAML.load_stream(File.open('mappings.yaml')).first

# Add a new key-value pair to the root of the first document.
if saved_words.empty? || saved_words[0].nil?
  saved_words[0] = []
end
# name -> def
ws = saved_words[0].map{|w| w[:front] }

@htmle = HTMLEntities.new

def cleanup(s)
  @htmle.decode(s).downcase.strip.gsub(/([,.:"“”()!?;])|(^')|(^‘)/, '').gsub(/(’$)|('$)/, '')
end

words.map!{|w| w[:word] = cleanup(w[:word]); w}.uniq!

words.keep_if do |w|
  ! ws.include? w[:word]
end

def getCanonicalForm(w)
  w =~ /(((alternative)|(plural)|(tense)|(participle)|(variant)).*of)|(\sa\s)/i
  if ($' && (can = cleanup($')) && !can.empty?)
    can
  else
    nil
  end    
end

def getSynsFor(w)
  if ((syns = Wordnik.word.get_related(w, :type => 'synonym', :use_canonical => true)) && 
      !syns.empty? &&
      (syns = syns[0]) &&
      !syns.empty? &&
      (syns = syns['words']) &&
      !syns.empty?) 
    syns
  else
    []
  end
end

def getWordDefs(w)
  if (defs = Wordnik.word.get_definitions(w, :use_canonical => true)) && 
      !defs.empty?
    defs
  else
    [] 
  end
end

@messages = []

def getWordInfo(w)
  defs = []
  syns = {}

  recDefs = lambda do |w|
    if (_defs = getWordDefs(w)) && !_defs.empty?
      defs += _defs
      _syns = getSynsFor(w)
      if (!_syns.empty?)
        syns[w] = _syns
      end
      if (_defs.length == 1 && 
          w == _defs.first['word'] && 
          (can = getCanonicalForm(_defs.first['text'])))
        @messages << "    Recursively looking for #{w} -> #{can}"
        recDefs.call(can)
      end
    else
       @messages << "  No definition found for '#{w}'."
    end
  end

  recDefs.call(w[:word])
  # Try mapping
  if defs.empty? && (map = @word_mappings[w[:word]])
      @messages << "    Trying mapping #{w[:word]} -> #{map.inspect}"
    if map.kind_of?(Array)
      map.each{|m| recDefs.call(cleanup(m))}
    else
      recDefs.call(cleanup(map))
    end
  end
  if defs.empty?
    nil
  else
    # Defintions
    wdef = "Definitions:<br>"
    defs.each do |definition|
      wdef += " - #{definition['word']}(#{definition['partOfSpeech']}): #{definition['text']}<br>"
    end
    # Synonyms
    if (!syns.empty?)
      wdef += "<br>Synonyms:<br>"
      syns.each do |key, val|
        wdef += " - #{key}: #{val.join(', ')}<br>"
      end
    end
    # Examples
    if ((examples = Wordnik.word.get_examples(w[:word])) && 
        (examples = examples['examples']) &&
        !examples.empty?)
      wdef += "<br>Examples:<br>"
      examples.each do |example|
        wdef += " - " + example['text'] + "<br>"
      end
    end
    {:front => w[:word], :back => wdef, :tag => w[:tags].join(' ')}
  end
end

puts "Fetching definitions for #{words.length.to_s} words"
ProgressBar.new("Wordnik", words.length) do |pbar|
  @new_defs = words.map do |w|
    info = getWordInfo(w)
    pbar.inc
    info || next
  end.compact
end

@messages.each do |message|
  puts message
end

unless @new_defs.empty?
  puts "Prepearing " + @new_defs.length.to_s + " new words for import"

  begin
    CSV.open(IMPORT_FILE, 'wb', {:col_sep => "\t"}) do |csv|
      @new_defs.each do |value|
        csv << value.values
      end
    end

    puts "Please manually open Anki select import csv from the Tools menu. Then close Anki and press ENTER to continue"
    STDIN.gets.chomp

  ensure
    begin
      File.delete(IMPORT_FILE)
    rescue
    end
  end
  unless @new_defs.empty?
    new_saved_words = saved_words[0] + @new_defs
    File.open('saved_words.yaml', 'w') do |file|
      file.write(YAML.dump(new_saved_words))
    end
  end
else
  puts "No new words to import"
end
