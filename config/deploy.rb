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

role :web, "192.168.56.101"                          # Your HTTP server, Apache/etc
#role :app, "192.168.56.101"                          # This may be the same as your `Web` server
#role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

set :deploy_to, "/home/ubuntu/www/#{application}"

namespace :deploy do
	task :start, :roles => :web do
	end
end

namespace :db do
end

namespace :memcached do
end

namespace :apache do
	task :start, :roles => :web do
		run "apache2ctl configtest"
		sudo "service apache2 start"
	end
	task :stop, :roles => :web do
		sudo "service apache2 stop"
	end
	task :restart, :roles => :web do
		run "apache2ctl configtest"
		sudo "service apache2 restart"
	end
end
