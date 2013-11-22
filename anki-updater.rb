#!/usr/bin/ruby

%w(rubygems wordnik yaml csv htmlentities green_shoes).each {|lib| require lib}
$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require "evernote.rb"
require "kindle.rb"
#require 'rubypython'


module StringUtils
  @@htmle = HTMLEntities.new

  def self.getCanonicalForm(w)
    def formOf(w)
      (w =~ /(((alternative)|(plural)|(tense)|(participle)|(variant)|(manner))[^.;]*of)/i) &&
      StringUtils.cleanup($')
    end

    def aSomething(w)
      (w =~ /^a\s([\w\-]+)/i) && StringUtils.cleanup($1)
    end

    def inManner(w)
      (w =~ /in.*?\s([\w\-]+)\smanner/i) && StringUtils.cleanup($1)
    end

    def trait(w)
      (w =~ /a(?:n)?.*?\s([\w\-]+)\s(?:(?:trait)|(?:mannerism))/i) && StringUtils.cleanup($1)
    end

    def cond(w)
      (w =~ /condition\sof\sbeing\s([\w\-]+)/i) && StringUtils.cleanup($1)
    end

    (can = formOf(w) || aSomething(w) || inManner(w) || trait(w) || cond(w)) && !can.empty? && can
  end

  def self.cleanup(s)
    @@htmle.decode(s).downcase.strip.gsub(/([,.:"“”()!?;])|(^')|(^‘)/, '').gsub(/(’$)|('$)/, '')
  end

end

class Importer
  IMPORT_FILE = "import.csv"
  MAPPINGS_FILE = "mappings.yaml"
  SAVED_WORDS_FILE = "saved_words.yaml"
  WORDNIK_API_KEY = "<Api-Key>"

  def initialize(logger = -> (s){puts s})
    @logger = logger
    init_clients(@logger)
    init_wordnik
    init_word_mappings
    init_saved_words
  end

  def num_new_words
    @new_words ||= get_new_words
    @new_words.length
  end

  def fetch_new_defs(inc = nil)
    @new_words ||= get_new_words
    @logger.call "Fetching definitions for #{@new_words.length.to_s} words"
    @new_defs = @new_words.map do |w|
      info = get_word_info(w[:word], w[:tags])
      inc.call if inc
      info || next
    end.compact
  end

  def export_csv
    CSV.open(IMPORT_FILE, 'wb', {:col_sep => "\t"}) do |csv|
      @new_defs.each do |value|
        csv << value.values
      end
    end
  end

  def delete_csv
    begin
      File.delete(IMPORT_FILE)
    rescue
    end
  end

private
  def init_clients(logger)
    @clients ||= [KindleWords::Client.new(logger), EvernoteWords::Client.new(logger)]
  end

  def init_wordnik
    Wordnik.configure do |config|
      config.api_key = WORDNIK_API_KEY
      config.logger = Logger.new('/dev/null')
    end
  end

  def init_word_mappings
    @word_mappings ||= YAML.load_stream(File.open(MAPPINGS_FILE)).first
  end

  def init_saved_words
    def get_saved_words
      # Load the file.
      saved_words = YAML.load_stream(File.open(SAVED_WORDS_FILE))

      # Add a new key-value pair to the root of the first document.
      if saved_words.empty? || saved_words[0].nil?
        saved_words[0] = []
      end
      
      saved_words[0].map{|w| w[:front] }
    end

    @saved_words ||= get_saved_words
  end

  def get_new_words
    words = @clients.reduce([]) do |memo, client|
      memo + client.getWords
    end

    words.map!{|w| w[:word] = StringUtils.cleanup(w[:word]); w}.uniq!

    words.select do |w|
      ! @saved_words.include? w[:word]
    end
  end

  def get_syns_for(w)
    (syns = Wordnik.word.get_related(w, :type => 'synonym', :use_canonical => true)) && 
    !syns.empty? &&
    (syns = syns[0]) &&
    !syns.empty? &&
    (syns = syns['words']) &&
    !syns.empty? &&
    syns ||
    []
  end

  def get_word_defs(w)
    (defs = Wordnik.word.get_definitions(w, :use_canonical => true)) && 
    !defs.empty? &&
    defs ||
    [] 
  end

  def get_defs_syns(w)
    defs = []
    syns = {}

    rec_defs = lambda do |w|
      if (_defs = get_word_defs(w)) && !_defs.empty?
        defs += _defs
        _syns = get_syns_for(w)
        if (!_syns.empty?)
          syns[w] = _syns
        end
        can = nil
        cansEqual = _defs.reduce(true) do |mem, d|
          mem && 
          (_can = StringUtils.getCanonicalForm(d['text'])) && 
          ((!can && (can = _can)) || _can == can)
        end
        if (can && cansEqual && can != w)
          @logger.call "  Recursively looking for #{w} -> #{can}"
          rec_defs.call(can)
        end
      else
         @logger.call "  No definition found for '#{w}'."
      end
    end

    rec_defs.call(w)
    # Try mapping
    if defs.empty? && (map = @word_mappings[w])
      @logger.call "    Trying mapping #{w} -> #{map.inspect}"
      if map.kind_of?(Array)
        map.each{|m| rec_defs.call(StringUtils.cleanup(m))}
      else
        rec_defs.call(StringUtils.cleanup(map))
      end
    end

    return defs, syns
  end

  def get_word_info(word, tags)
    defs, syns = get_defs_syns(word)
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
      if ((examples = Wordnik.word.get_examples(word)) && 
          (examples = examples['examples']) &&
          !examples.empty?)
        wdef += "<br>Examples:<br>"
        examples.each do |example|
          wdef += " - " + example['text'] + "<br>"
        end
      end
      {:front => word, :back => wdef, :tag => tags.join(' ')}
    end
  end

end

Shoes.app title: "Anki Importer 0.1" do
  @main_stack = stack do
    button "Start fetching"
    @p = progress left: 10, top: 100, width: width-20
    flow do
      para "Status: "
      @status = para "Setting up"
    end
  end

  Thread.new do
    a = animate do |i|
      @p.fraction = (i % 100) / 100.0
    end

    @imp = Importer.new ->(s){puts s;@status.replace s}
    @total_words = @imp.num_new_words
    # Finish init
    a.stop
    @p.fraction = 0
    @status.replace "Initialization finished"

    def fetch_defs
      i = 0
      a = animate do |_|
        @p.fraction = i / @total_words
      end

      @new_defs = @imp.fetch_new_defs -> {i+=1}
      a.stop
      @p.fraction = 0
      @status.replace "Finished fetching word definitions"
    end

    fetch_defs

    @main_stack.append do 
      button "Refetch defs" do
        fetch_defs
      end
      @b = button "Create CSV" do
        @imp.export_csv
        @b.replace "Exit" do 
          @imp.delete_csv
          close
        end
      end
    end
  end




  

=begin
      unless @new_defs.empty?
        new_saved_words = saved_words[0] + @new_defs
        File.open('saved_words.yaml', 'w') do |file|
          file.write(YAML.dump(new_saved_words))
        end
      end
=end
end
