require "digest/md5"
require 'evernote-thrift'
require 'nokogiri'

module AnkiWordTeacher
  module EvernoteWords
    class Client
      #attr :authToken, :noteStore
      FILTER = AnkiWordTeacher.configuration.evernote_filter
  
      def initialize(logger = ->(s){@logger.call s})
        @logger = logger
        @logger.call "Start Evernote init"
        initAuthToken
        initNoteStore
        initTagList
        @logger.call "Finish Everenote init"
      end
  
      def initAuthToken
        # Real applications authenticate with Evernote using OAuth, but for the
        # purpose of exploring the API, you can get a developer token that allows
        # you to access your own Evernote account. To get a developer token, visit
        # https://sandbox.evernote.com/api/DeveloperToken.action
  
        @authToken = AnkiWordTeacher.configuration.evernote_auth_token
  
        if !@authToken || @authToken == "your developer token"
          @logger.call "Please fill in your developer token"
          @logger.call "To get a developer token, visit https://sandbox.evernote.com/api/DeveloperToken.action"
          exit(1)
        end
      end
  
      def initNoteStore
        # Initial development is performed on our sandbox server. To use the production
        # service, change "sandbox.evernote.com" to "www.evernote.com" and replace your
        # developer token above with a token from
        # https://www.evernote.com/api/DeveloperToken.action
        evernoteHost = "www.evernote.com"
        userStoreUrl = "https://#{evernoteHost}/edam/user"
  
        userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
        userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
        userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
  
        versionOK = userStore.checkVersion("Evernote EDAMTest (Ruby)",
                   Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
                   Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
        #@logger.call "Is my Evernote API version up to date?  #{versionOK}"
        #@logger.call
        exit(1) unless versionOK
  
        # Get the URL used to interact with the contents of the user's account
        # When your application authenticates using OAuth, the NoteStore URL will
        # be returned along with the auth token in the final OAuth request.
        # In that case, you don't need to make this call.
        noteStoreUrl = userStore.getNoteStoreUrl(@authToken)
  
        noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
        noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
        @noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
      end
  
      def initTagList
        @tagList = @noteStore.listTags(@authToken)
      end
  
      def getWords
        @logger.call "Start fetching words from evernote"
        filter = Evernote::EDAM::NoteStore::NoteFilter.new
        filter.words = FILTER
        spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new
        notesMetadata = @noteStore.findNotesMetadata(@authToken, filter, 0, 9999, spec)
        @logger.call "Downloading content for " + notesMetadata.notes.length.to_s + " words"
  
        notesMetadata.notes.map do |meta|
          note = @noteStore.getNote(@authToken, meta.guid, true, false, false, false)
          content = Nokogiri::XML(note.content)
          tags = @tagList.select{|t|note.tagGuids.include?(t.guid) && !t.name.eql?('#Word')}.map{|t| t.name} << "evernote"
          # Get leaf divs
          content.xpath('//div[not(child::*)]').map do |div|
            {:word => div.content, :tags => tags}
          end
        end.flatten
      end
    end
  end
end
