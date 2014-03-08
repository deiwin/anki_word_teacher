module AnkiWordTeacher
  module KindleWords
    class Client
      require 'kindle-your-highlights'
      require 'yaml'
      require 'csv'
      require 'net/http'
  
      def initialize(logger = ->(s){puts s})
        @logger = logger
        @logger.call "Start Kindle init"
        initKindle
        @logger.call "Finish Kindle init"
      end
  
      def initKindle
        # pass in your Amazon credentials. Loads your books (not highlights) on init, so might take a while                                                             
        @kindle = KindleYourHighlights.new(AnkiWordTeacher.configuration.kindle_email, AnkiWordTeacher.configuration.kindle_password, :wait_time => 20, :page_limit => 100) do | h |
          if h.books.last
            @logger.call "loading... [#{h.books.last.title}] - #{h.books.last.last_update}"
          end
        end
      end
  
      def getWords
        @logger.call "Start fetching Kindle highlights"
        @kindle.list.highlights.map do |highlight|
          # Less than 3 words
          if highlight.content.split.size <= 2
            tags = ["kindle", highlight.title.downcase.gsub(/\s/,'-')]
            {:word => highlight.content, :tags => tags}
          else
            next
          end
        end.compact
      end
    end
  end
end 
