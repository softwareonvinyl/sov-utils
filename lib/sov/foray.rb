require 'sov/utils/io'
require 'sov/utils/db'
require 'sov/utils/branch_management'
require 'pry'

class Sov::Foray
    extend Sov::Utils::IO::CLASS_METHODS
    include Sov::Utils::IO::INSTANCE_METHODS

    extend Sov::Utils::BranchManagement::CLASS_METHODS
    include Sov::Utils::BranchManagement::INSTANCE_METHODS

    extend Sov::Utils::DB::CLASS_METHODS
    include Sov::Utils::DB::INSTANCE_METHODS

    def initialize(options={})
      @task = options[:task]
      @dump_dir = options[:custom_dump_dir] || Sov::Utils::DUMP_DIR
      @project_dir = options[:custom_project_dir] || '.'
      @verbose = options[:verbose]
      @new_branch = options[:new_branch]
      @capture_fresh = options[:capture_fresh]
      @hotfix = options[:hotfix]
      @new_dump = options[:new_dump]
      @app_name = options[:app_name]
      @db_name = options[:db_name]

      if @task == 'db_restore'
        if @app_name.nil?
          error_out_with_message("You must specify an --app_name=<value>")
        end
        if @db_name.nil?
          error_out_with_message("You must specify an --db_name=<value>")
        end
      end
    end

    def start!
      if @task == 'db_restore'
        verify_system_requirements

        obtain_branch_information

        setup_dump_file

        ensure_processes_killed

        setup_db
      elsif @task == 'help'
        run_help
      else
        raise('You must specify a legitimate task.')
      end
    end

    def run_help
      options = [
        '--custom_dump_dir=<value>',
        '--custom_project_dir=<value>',
        '--verbose',
        '--old_branch',
        '--new_branch',
        '--not_hotfix',
        '--hotfix',
        '--existing_dump',
        '--new_dump',
        '--capture_fresh',
        '--do_not_capture_fresh',
        '--app_name=<value>',
        '--db_name=<value>'
      ]

      message = "Current tasks are 'db_restore' 'help'\n"
      message += "The configurable options are as such:\n"
      message += options.join(", \n")
      message += "\n"
      message += 'NOTE: Be sure to not add any extra spaces in the variable declarations!'

      print(message)
    end
end
