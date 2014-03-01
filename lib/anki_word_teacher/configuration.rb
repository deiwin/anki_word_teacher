require 'logger'

module AnkiWordTeacher
  class Configuration
    attr_accessor :import_file, :mappings_file, :saved_words_file
    attr_accessor :wordnik_api_key
    attr_accessor :evernote_auth_token, :evernote_filter
    attr_accessor :logger
    attr_accessor :kindle_email, :kindle_password, :kindle_books

    def initialize
      @logger = Logger.new(STDOUT)

      @import_file = "import.csv"
      @mappings_file = "mappings.yaml"
      @saved_words_file = "saved_words.yaml"

      @evernote_filter = "tag:#Word"
    end

  end
end
