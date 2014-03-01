require 'kindle_highlights'
require 'yaml'
require 'csv'
require 'net/http'

module AnkiWordTeacher
  module KindleWords
    class Client
  
      BOOKS = AnkiWordTeacher.configuration.kindle_books
      EMAIL = AnkiWordTeacher.configuration.kindle_email
      PASS = AnkiWordTeacher.configuration.kindle_password
  
      def initialize(logger = ->(s){puts s})
        @logger = logger
        @logger.call "Start Kindle init"
        initKindle
        @logger.call "Finish Kindle init"
      end
  
      def initKindle
        # pass in your Amazon credentials. Loads your books (not highlights) on init, so might take a while                                                             
        @kindle = KindleHighlights::Client.new(EMAIL, PASS)
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
end 
