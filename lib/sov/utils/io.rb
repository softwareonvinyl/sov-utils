# I/O Utilities

module Sov
  module Utils
    module IO
      module ClassMethods
      end

      module InstanceMethods
        def error_out_with_message(message)
          raise message
        end

        def run(command)
          puts "Running `#{command}`"
          `#{command}`.chop
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
