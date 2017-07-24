# I/O Utilities

module Sov
  module Utils
    module IO
      module CLASS_METHODS
      end

      module INSTANCE_METHODS
        def error_out_with_message(message)
          raise message
        end

        def run(command)
          puts "Running `#{command}`" if @verbose
          `#{command}`.chop
        end

        def print_update(message)
          puts message if @verbose
        end

        def print(message)
          puts message
        end

        def read_input
          selection = gets
          selection.chomp
        end

        def ask_yes_no(message)
          print("#{message} (yes)(default) (no)")
          selection = gets
          (selection =~ /[N,n]/).nil?
        end
      end
    end
  end
end
