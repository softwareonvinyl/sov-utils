require 'sov/utils/constants'
require 'fileutils'

module Sov
  module Utils
    module DB
      module CLASS_METHODS
      end

      module INSTANCE_METHODS
        def verify_system_requirements
          ensure_pg_version
          ensure_pg_running

          ensure_bundler_version

          ensure_newest_util_version

          ensure_correct_directory

          ensure_dump_dir
          ensure_ignored_dump_files
          ensure_dump_files_count
        end

        def setup_dump_file
          @dump_avail = has_dump_present?

          if @dump_avail
            @diff_latest_dump = ask_yes_no('Would you like to use the latest dump?')
          end

          if @diff_latest_dump
            @dump_file_name = latest_dump
          else
            if @dump_avail
              @download_fresh = ask_yes_no('Would you like to download a fresh dump?')
            end

            if @download_fresh || !@dump_avail
              @capture_fresh = ask_yes_no(
                'Would you like to capture a fresh backup before downloading the dump file?'
              )

              print('From where would you like to obtain your new dump?')
              print('1) DEV (default)')
              print('2) DEMO')
              print('3) PROD')
              selection = read_input

              puts "check this out #{selection}"
              case selection
                when '2'
                  download_dump_file(:demo, @capture_fresh)
                when '3'
                  download_dump_file(:prod, @capture_fresh)
                else
                  download_dump_file(:dev, @capture_fresh)
              end
            end

            @dump_file_name = latest_dump
          end
        end

        def ensure_processes_killed
          processes = run('ps wax | grep foreman:').split(/\n/).reject { |s| s.include?('grep') }
          return false unless processes.length > 0

          print('Foreman can not be running. About to kill it.')
          pid = processes.first.split(' ').first

          run("kill -9 #{pid}")
        end

        def setup_db
          run('bundle exec rake db:drop')

          run('bundle exec rake db:create')

          dump_file_path = "#{@dump_dir}/#{@dump_file_name}"
          run("pg_restore -c --no-owner --no-privileges -d shopware_dev #{dump_file_path}")

          run('bundle exec rake db:migrate')

          run('bundle exec rake db:sanitize')
        end

        # Ensure Methods

        def ensure_pg_version
          if pg_supported_version?
            print('You are currently using the correct Postgres version.')
          else
            message = "Your current version of Postgresql is unsupported. " +
              "#{PSQL_VERSION} is the supported version."
            error_out_with_message(message)
          end
        end

        def ensure_pg_running
          if pg_running?
            print('Postgres is currently running.')
          else
            message = 'Postgres is not currently running. Please start it.'
            error_out_with_message(message)
          end
        end

        def ensure_bundler_version
          if bundler_supported_version?
            print('You are currently using the correct Bundler version.')
          else
            message = "Your current version of Bundler is unsupported. " +
              "#{BUNDLER_VERSION} is the supported version."
            error_out_with_message(message)
          end
        end

        def ensure_newest_util_version
          if newest_util_version?
            print('You are currently using the correct Sov::Utils version.')
          else
            message = "Please upgrade Sov::Utils to the newest version: #{@newest_utils_version}"
            error_out_with_message(message)
          end
        end

        def ensure_correct_directory
          if @skip_dir_check
            print('You have elected to skip the directory check.')
          elsif shopware_dir?
            print('You are currently in the correct directory.')
          else
            message = 'Please navigate to the shop-ware project.'
            error_out_with_message(message)
          end
        end

        def ensure_dump_dir
          FileUtils.mkdir_p(@dump_dir)
        end

        def ensure_ignored_dump_files
          if ignoring_dump_dir?
            print('Your git ignore settings are correct.')
          else
            message = "Your git ignore settings are not correct. " +
              "Please add #{Sov::Utils::DUMP_DIR} to the git ignore file."
            error_out_with_message(message)
          end
        end

        def ensure_dump_files_count
          dump_count = run("ls #{@dump_dir}").split(/\n/).length

          return false unless dump_count > Sov::Utils::DUMP_MAX_COUNT

          print("Your system currently has #{dump_count}. " +
                  "#{Sov::Utils::DUMP_MAX_COUNT} is the configured max.")
          print('Would you like to:')
          print('1) Do nothing')
          print('2) Clear out the directory')
          print('3) Delete half the oldest dumps')
          print('4) Delete the oldest dump')

          selection = read_input

          case selection.chomp
          when '2'
            run("rm #{@dump_dir}/*.dump")
          when '3'
            (dump_count / 2).to_i.times do
              remove_oldest_dump
            end
          when '4'
            remove_oldest_dump
          else
            print('You have have selected to do nothing about the dump files.')
          end
        end

        # DB Utilities

        def remove_oldest_dump
          last_dump = run("ls #{@dump_dir}").split(/\n/).last
          run("rm #{@dump_dir}/#{last_dump}")
        end

        def latest_dump
          run("ls #{@dump_dir}").split(/\n/).first
        end

        def download_dump_file(location_sym, fresh)
          puts location_sym
          if location_sym == :demo
            app_name = 'shopware-demo'
          elsif location_sym == :prod
            app_name = 'shopware'
          elsif location_sym == :dev
            app_name = 'shopware-dev'
          end

          run("heroku pg:backups:capture --app #{app_name}") if fresh

          run('rm *.dump*')

          new_dump_name = "#{Time.now.to_i}_#{app_name}.dump"

          run("heroku pg:backups:download -a #{app_name}")

          run("mv latest.dump #{@dump_dir}/#{new_dump_name}")
        end

        # Bool Checkers

        def pg_running?
          run('ps aux | grep bin/postgres').include?('/bin/postgres')
        end

        def pg_supported_version?
          run('psql --version').include?(Sov::Utils::PSQL_VERSION)
        end

        def bundler_supported_version?
          run('bundle -v').include?(Sov::Utils::BUNDLER_VERSION)
        end

        def newest_util_version?
          newest_version_s = run("gem list #{Sov::Utils::PACKAGE_NAME} --remote")

          return true if newest_version_s.empty?

          newest_version = newest_version_s.delete('^0-9')

          current_version_s = run('gem which')
          current_version = current_version_s.delete('^0-9')

          newest_version == current_version
        end

        def shopware_dir?
          run('pwd').split('/').last == Sov::Utils::PROJECT_NAME
        end

        def ignoring_dump_dir?
          run("cat #{@project_dir}/.gitignore | grep #{@dump_dir}")
        end
      end
    end
  end
end
