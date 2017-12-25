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

          ensure_dump_dir
          ensure_ignored_dump_files
          ensure_dump_files_count
        end

        def setup_dump_file
          @dump_avail = has_dump_present?

          @option_specified = !@new_dump.nil?

          if @option_specified && @new_dump == false && !@dump_avail
            error_out_with_message('There is not an existing dump to use.')
          end

          if @dump_avail
            @new_dump = if @new_dump.nil?
                          !ask_yes_no('Would you like to use a previously downloaded dump?')
                        else
                          @new_dump
                        end
          else
            @new_dump = true
          end

          if !@new_dump
            @dump_file_name = latest_dump
          else
            @capture_fresh = if @capture_fresh.nil?
                               ask_yes_no(
                                 'Would you like to capture a fresh backup before '\
                                 'downloading the dump file?'
                               )
                             else
                               @capture_fresh
                             end

            if @app_name.nil?
              error_out_with_message('You must specify an app on which to deploy.')
            end

            download_dump_file
          end

          @dump_file_name = latest_dump
        end

        def ensure_processes_killed
          processes = run('ps wax | grep foreman:').split(/\n/).reject { |s| s.include?('grep') }
          return false unless processes.length > 0

          print_update('Foreman can not be running. About to kill it.')
          pid = processes.first.split(' ').first

          run("kill -9 #{pid}")
        end

        def setup_db
          run('bundle exec rake db:drop')

          run('bundle exec rake db:create')

          dump_file_path = "#{@dump_dir}/#{@dump_file_name}"
          system("pg_restore -c --no-owner --no-privileges -d #{@db_name} #{dump_file_path}")

          run('bundle exec rake db:migrate')

          run('bundle exec rake db:sanitize')

          if run('bundle exec rake -T').include?('db:sov_utils:after_setup')
            run('bundle exec rake db:sov_utils:after_setup')
          end
        end

        # Ensure Methods

        def ensure_pg_version
          if pg_supported_version?
            print_update('You are currently using the correct Postgres version.')
          else
            message = "Your current version of Postgresql is unsupported. " +
              "#{@config.psql_version} is the supported version."
            error_out_with_message(message)
          end
        end

        def ensure_pg_running
          if pg_running?
            print_update('Postgres is currently running.')
          else
            message = 'Postgres is not currently running. Please start it.'
            error_out_with_message(message)
          end
        end

        def ensure_bundler_version
          if bundler_supported_version?
            print_update('You are currently using the correct Bundler version.')
          else
            message = "Your current version of Bundler is unsupported. " +
              "#{@config.bundler_version} is the supported version."
            error_out_with_message(message)
          end
        end

        def ensure_newest_util_version
          if newest_util_version?
            print_update('You are currently using the correct Sov::Utils version.')
          else
            message = "Please upgrade Sov::Utils to the newest version: #{@newest_utils_version}"
            error_out_with_message(message)
          end
        end

        def ensure_dump_dir
          FileUtils.mkdir_p(@dump_dir)
        end

        def ensure_ignored_dump_files
          if ignoring_dump_dir?
            print_update('Your git ignore settings are correct.')
          else
            message = "Your git ignore settings are not correct. " +
              "Please add #{@dump_dir} to the git ignore file."
            error_out_with_message(message)
          end
        end

        def ensure_dump_files_count
          dump_count = run("ls #{@dump_dir}").split(/\n/).length

          return false unless dump_count > @config.dump_max_count

          print("Your system currently has #{dump_count}. " +
                  "#{@config.dump_max_count} is the configured max.")
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

        def download_dump_file
          run("heroku pg:backups:capture --app #{@app_name}") if @capture_fresh

          new_dump_name = "#{Time.now.to_i}_#{@app_name}.dump"

          heroku_dump_file_name = 'latest.dump'
          run('rm latest.dump') if File.exist?(heroku_dump_file_name)
          run("heroku pg:backups:download -a #{@app_name}")

          run("mv #{heroku_dump_file_name} #{@dump_dir}/#{new_dump_name}")
        end

        # Bool Checkers

        def pg_running?
          run('ps aux | grep bin/postgres').include?('/bin/postgres')
        end

        def pg_supported_version?
          run('psql --version').include?(@config.psql_version)
        end

        def bundler_supported_version?
          run('bundle -v').include?(@config.bundler_version)
        end

        def newest_util_version?
          newest_version_s = run("gem list #{Sov::Utils::PACKAGE_NAME} --remote")

          return true if newest_version_s.empty?

          newest_version = newest_version_s.delete('^0-9')

          current_version_s = run('gem which')
          current_version = current_version_s.delete('^0-9')

          newest_version == current_version
        end

        def ignoring_dump_dir?
          run("cat #{@project_dir}/.gitignore | grep #{@dump_dir}")
        end
      end
    end
  end
end
