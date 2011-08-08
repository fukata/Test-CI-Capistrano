# how to use sudo
# $ sudo visudo
# Defaults visiblepw

set :application, "CapistranoTest"
set :repository,  "git://github.com/fukata/Test-CI-Capistrano.git"

set :scm, :git
set :deploy_via, :copy
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :user, "ubuntu"
set :password, "ubuntu"
set :use_sudo, false 

# roles
role :web, "192.168.56.101"                          # Your HTTP server, Apache/etc
role :db,  "192.168.56.101", :primary => true # This is where Rails migrations will run
role :memcache, "192.168.56.101"
set :deploy_to, "/home/ubuntu/www/#{application}"

namespace :deploy do
	task :start, :roles => :web do
		run "apache2ctl configtest"
		sudo "service apache2 restart"
	end

	task :stop, :roles => :web do
		sudo "service apache2 stop"
	end

	task :restart, :roles => :web do
		run "apache2ctl configtest"
		sudo "service apache2 restart"
	end

	task :finalize_update, :except => { :no_release => true } do
		diff_source
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

def diff_source
	set :diff_prev, ENV['DIFF_PREV']
	set :diff_current, ENV['DIFF_CURRENT']
	set :diff_scm_exclude, ENV['DIFF_SCM_EXCLUDE'] || ".git"
	set :diff_local_exclude, ENV['DIFF_LOCAL_EXCLUDE'] || "--exclude=.git --exclude=REVISION --exclude=log"
	return if (ENV['DIFF'] == 0)

	run <<-CMD
		echo 'finalize_update';

		# initialize
		latest=$(basename "#{latest_release}");
		cp -R #{latest_release} /tmp/${latest}_#{diff_current};
		cp -R #{latest_release} /tmp/${latest}_#{diff_prev};
		cd /tmp/${latest}_#{diff_prev};
		git checkout -f #{diff_prev} 2>&1 >> /dev/null;

		# diff
		cd /tmp;
		scmdiff_sed="s@^(\\-\\-\\-|\\+\\+\\+) (/tmp/${latest}_#{diff_prev}|/tmp/${latest}_#{diff_current})/(.+)\t([0-9]{4}\-[0-9]{2}\-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{1,10} \-[0-9]{4})@\\1 \\3@g";
		scmdiff="$(diff -ru #{diff_local_exclude} /tmp/${latest}_#{diff_prev} /tmp/${latest}_#{diff_current}| egrep -v '^diff'| sed -r \"${scmdiff_sed}\")";
		localdiff_sed="s@^(\\-\\-\\-|\\+\\+\\+) (#{previous_release}|#{latest_release})/(.+)\t([0-9]{4}\-[0-9]{2}\-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{1,10} \-[0-9]{4})@\\1 \\3@g";
		localdiff="$(diff -ru #{diff_local_exclude} #{previous_release} #{latest_release}| egrep -v '^diff'| sed -r \"${localdiff_sed}\")";

		# remove temporary directories.
		rm -fr "/tmp/${latest}_#{diff_current}";
		rm -fr "/tmp/${latest}_#{diff_prev}";

		if [ "$scmdiff" != "$localdiff" ]; then
			echo '========NOT SAME SOURCE========';
			echo "========LOCAL========";
			echo "$localdiff";
			echo "========SCM========";
			echo "$scmdiff";
	    	exit 1;
		else
			echo '========SAME SOURCE========';
		fi
	CMD
end
 
