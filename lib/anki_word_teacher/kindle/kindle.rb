require 'kindle_highlights'
require 'yaml'
require 'csv'
require 'net/http'

module KindleWords
  class Client

    BOOKS = ["Cloud Atlas"]

    def initialize(logger = -> (s){puts s})
      @logger = logger
      @logger.call "Start Kindle init"
      initKindle
      @logger.call "Finish Kindle init"
    end

    def initKindle
      passwords = File.open('.pw', 'r')
      line = passwords.gets.chomp
      passwords.close

      # pass in your Amazon credentials. Loads your books (not highlights) on init, so might take a while                                                             
      @kindle = KindleHighlights::Client.new("<email>", line) 
    end

    def getWords
      @logger.call "Start fetching Kindle highlights"
      BOOKS.map do |book_name|
        @logger.call "Fetching highlights for book " + book_name
        book = @kindle.books.select {|k| @kindle.books[k].include? book_name}
        # Get the key of the first book
        book_hash = book.first.first
        tags = ["kindle", book_name.downcase.gsub(/\s/,'-')]
        @kindle.highlights_for(book_hash).map do |h|
          {:word => h['highlight'], :tags => tags}
        end
      end.flatten
    end

  end
end

