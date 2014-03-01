require 'wordnik'
require 'yaml'
require 'csv'
require 'evernote/evernote'
require 'kindle/kindle'
require 'string_utils'

class AnkiImporter
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

    yield IMPORT_FILE

    begin
      File.delete(IMPORT_FILE)
    rescue
    end

    save_exported_words
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
    @word_mappings ||= YAML.load_file(MAPPINGS_FILE).first
  end

  def init_saved_words
    def get_saved_words
      # Load the file.
      @saved_words_raw = YAML.load_file(SAVED_WORDS_FILE)

      # Add a new key-value pair to the root of the first document.
      if @saved_words_raw.empty? || @saved_words_raw[0].nil?
        @saved_words_raw[0] = []
      end
      
      @saved_words_raw[0].map{|w| w[:front] }
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

    # Force mapping
    if map = @word_mappings[w]
      @logger.call "  Mapping #{w} -> #{map.inspect}"
      if map.kind_of?(Array)
        map.each{|m| rec_defs.call(StringUtils.cleanup(m))}
      else
        rec_defs.call(StringUtils.cleanup(map))
      end
    else
      rec_defs.call(w)
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

  def save_exported_words
    unless @new_defs.empty?
      new_saved_words = @saved_words_raw[0] + @new_defs
      File.open(SAVED_WORDS_FILE, 'w') do |file|
        file.write(YAML.dump(new_saved_words))
      end
    end
  end

end
