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
      @skip_dir_check = options[:skip_dir_check]
      @dump_dir = options[:custom_dump_dir] || Sov::Utils::DUMP_DIR
      @project_dir = options[:custom_project_dir] || '.'
    end

    def start!
      verify_system_requirements

      obtain_branch_information

      setup_dump_file

      ensure_processes_killed

      setup_db
    end
end
