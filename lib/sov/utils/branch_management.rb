require 'sov/utils/constants'

module Sov
  module Utils
    module BranchManagement
      module CLASS_METHODS
      end

      module INSTANCE_METHODS
        def new_branch?
          @new_branch = @new_branch.nil? ? ask_yes_no('Is this a new branch?') : @new_branch
        end

        def hotfix?
          @hotfix = @hotfix.nil? ? ask_yes_no('Is this a hotfix branch?') : @hotfix
        end

        def obtain_branch_information
          new_branch?

          hotfix?

          if @hotfix
            ensure_rel_current
            ensure_current_branch_rel_ancestor
          else
            ensure_master_current
            ensure_current_branch_master_ancestor
          end
        end

        # Ensure Methods

        def ensure_rel_current
          if is_rel_current?
            print('Rel is currently up to date with origin.')
          else
            message = 'Rel is not currently up to date with origin. Please correct that.'
            error_out_with_message(message)
          end
        end

        def ensure_master_current
          if is_master_current?
            print('Master is currently up to date with origin.')
          else
            message = 'Master is not currently up to date with origin. Please correct that.'
            error_out_with_message(message)
          end
        end

        def ensure_current_branch_rel_ancestor
          fail_message = ' is not based on rel and is there not eligible for a hotfix.'
          success_message = ' is based on rel and is an eligible hotfix.'

          ensure_current_branch_is_ancestor_of('rel', fail_message, success_message)
        end

        def ensure_current_branch_master_ancestor
          fail_message = ' is not based on master. Please rebase on master'
          success_message = ' is based on master.'

          ensure_current_branch_is_ancestor_of('master', fail_message, success_message)
        end

        def ensure_current_branch_is_ancestor_of(branch, fail_message, success_message)
          current_branch_name = run('git rev-parse --abbrev-ref HEAD')
          if current_branch_name == 'HEAD'
            message = 'You must be on a branch.'
            error_out_with_message(message)
          end

          if run('git branch | grep sov-utils-tmp').length > 0
            run('git branch -D sov-utils-tmp')
          end

          run('git checkout -b sov-utils-tmp')

          if run("git branch --contains #{branch}").include?(current_branch_name)
            run("git checkout #{current_branch_name}")
            run('git branch -D sov-utils-tmp')

            print(current_branch_name + success_message)
          else
            run("git checkout #{current_branch_name}")
            run('git branch -D sov-utils-tmp')

            message = current_branch_name + fail_message
            error_out_with_message(message)
          end
        end

        # Bool Checkers

        def has_dump_present?
          run("ls #{@dump_dir}").split(/\n/).length > 0
        end

        def is_rel_current?
          run('git rev-parse origin/rel') == run('git rev-parse rel')
        end

        def is_master_current?
          run('git rev-parse origin/master') == run('git rev-parse master')
        end
      end
    end
  end
end
