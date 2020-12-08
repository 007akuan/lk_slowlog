# config valid for current version and patch releases of Capistrano
lock "~> 3.14.1"

set :application, "lk_slowlog"
set :repo_url, "https://github.com/007akuan/lk_slowlog.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :rvm_ruby_version, '2.7.0'

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"
set :linked_files, %w{
  config/database.yml config/puma.rb config/secrets.yml
}

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
set :linked_dirs, %w{
  log tmp/pids tmp/sockets
}
# remove :linked_dirs, "public/assets"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Skip migration if files in db/migrate were not modified
set :conditionally_migrate, true

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :puma_preload_app, true
set :puma_init_active_record, true
set :puma_control_app, true

namespace :deploy do
  after 'deploy:publishing', 'deploy:restart'

  desc 'cp assets/images to public/assets'
  before :restart, :cp_assets do
    on roles(:web), in: :sequence, wait: 5 do
      # execute :cp, '-R', release_path.join('app/assets/images/*'), release_path.join('public/assets/')
      # execute :cp, '-R', release_path.join('app/assets/stylesheets/*'), release_path.join('public/assets/')
    end
  end

  task :run_code_check do
    on roles(:all) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # execute :rake, 'app:check'
          execute :bundle, %Q{exec rails runner "print %[It looks ok]" 2>&1}
        end
      end
    end
  end
  before "deploy:updated", "deploy:run_code_check"

  desc "run rake task on remote server 'cap qa deploy:runrake task=stats'"
  task :runrake do
    on roles(:db), in: :groups, limit: 1, wait: 10 do
      within current_path do
        with rails_env: fetch(:rails_env) do
          rake ENV['task']
        end
      end
    end
  end

  desc 'upload setup_config for application'
  task :upload_config do
    on roles(:web), in: :sequence, wait: 5 do
      invoke "deploy:check:make_linked_dirs"

      fetch(:linked_files).each do |file_path|
        unless test "[ -f #{shared_path}/#{file_path} ]"
          upload!("#{file_path}", "#{shared_path}/#{file_path}", via: :scp)
        end
      end
    end
  end

  desc 'update git remote repo url'
  task :update_git_repo do
    on release_roles :all do
      with fetch(:git_environmental_variables) do
        within repo_path do
          current_repo_url = execute :git, :config, :'--get', :'remote.origin.url'
          unless repo_url == current_repo_url
            execute :git, :remote, :'set-url', 'origin', repo_url
            execute :git, :remote, :update

            execute :git, :config, :'--get', :'remote.origin.url'
          end
        end
      end
    end
  end
end
