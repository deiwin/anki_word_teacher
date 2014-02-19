#!/usr/bin/ruby

%w(green_shoes).each {|lib| require lib}
$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require "anki-updater.rb"

Shoes.app title: "Anki Importer 0.1" do
  @logger = ->(s){puts s;@status.replace s}
  @main_stack = stack do
    button "Start fetching"
    @p = progress left: 10, top: 250, width: width-20
    flow do
      para "Status: "
      @status = para "Setting up"
    end
  end

  Thread.new do
    a = animate do |i|
      @p.fraction = (i % 100) / 100.0
    end

    @imp = AnkiImporter.new @logger
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
      button "Finish" do
        @export_thread = Thread.new do
          @imp.export_csv do
            @main_stack.append do
              button "Done" do
                @export_thread.run
              end
            end
            Thread.stop
          end
          close
        end
      end
    end
  end
end

