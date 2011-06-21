# how to use sudo
# $ sudo visudo
# Defaults visiblepw

set :application, "CapistranoTest"
set :repository,  "git://github.com/fukata/Test-CI-Capistrano.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :user, "ubuntu"
set :password, "ubuntu"
set :use_sudo, false 

#role :web, "192.168.56.101"                          # your http server, apache/etc
#role :app, "192.168.56.101"                          # this may be the same as your `web` server
#role :db,  "192.168.56.101", :primary => true # this is where rails migrations will run
#role :db,  "your slave db-server here"

#set :deploy_to, "/home/ubuntu/www/#{application}"

task :dev do
	# roles
	role :web, "192.168.56.101"                          # Your HTTP server, Apache/etc
	role :db,  "192.168.56.101", :primary => true # This is where Rails migrations will run
	role :memcache, "192.168.56.101"

	set :deploy_to, "/home/ubuntu/www/#{application}"
	common_task
end

task :common_task do

	namespace :deploy do
		task :start, :roles => :web do
			run "apache2ctl configtest"
			sudo "service apache2 restart"
		end

		task :stop, :roles => :web do
			sudo "service apache2 stop"
		end
	end

	namespace :db do
		set :db_service, "mysql"
		task :start, :roles => :db do
			sudo "service #{db_service} restart"
		end
		task :stop, :roles => :db do
			sudo "service #{db_service} stop"
		end
	end

	namespace :memcache do
		task :start, :roles => :memcache do
			sudo "service memcached restart"
		end
	end

end
