require 'rubygems'
require 'bundler/setup'
require 'anki_word_teacher/anki_updater'
require 'anki_word_teacher/configuration'
require 'logger'

module AnkiWordTeacher
  class << self
    attr_accessor :configuration, :logger
    def configure(&block)
      self.configuration ||= Configuration.new
      yield (configuration)
      self.logger ||= configuration.logger

      if !configuration.wordnik_api_key
        raise "No Wordnik API key set."
      end
    end
  end
end
