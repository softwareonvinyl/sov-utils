require 'sov/utils/constants'
require 'fileutils'
require 'yaml'

module Sov
  module Utils
    module Config
      module CLASS_METHODS
      end

      module INSTANCE_METHODS
        def initialize
          error_out_with_message('Configuration file not present') unless File.exists?('.sov_utils.yml')
          @config = YAML.load_file('.sov_utils.yml')
        end

        def psql_version
          @config.fetch('psql_version')
        end

        def bundler_version
          @config.fetch('bundler_version')
        end

        def dump_dir
          @config.fetch('dump_dir')
        end

        def dump_max_count
          @config.fetch('dump_max_count')
        end
      end
    end
  end
end
