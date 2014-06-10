# coding: utf-8
require 'rake/clean'

HOME = ENV["HOME"]
OS = `uname`


DIR_ATOM	=	File.join(File.dirname(__FILE__), "atom")
DIR_BASH	=	File.join(File.dirname(__FILE__), "bash")
DIR_GIT		=	File.join(File.dirname(__FILE__), "git")
DIR_GO		=	File.join(File.dirname(__FILE__), "go")
DIR_MAC		=	File.join(File.dirname(__FILE__), "mac")
DIR_RUBY	=	File.join(File.dirname(__FILE__), "ruby")
DIR_TMUX	=	File.join(File.dirname(__FILE__), "tmux")
DIR_VIM		=	File.join(File.dirname(__FILE__), "vim")

cleans = [
	".atom",
	".bash_profile",
	".bashrc",
	".gitconfig",
	".gitignore.global",
	".tmux.conf",
	".vim",
	".vimrc",
	".vimrc_neocomplete",
	".gemrc"
]

CLEAN.concat(cleans.map{|c| File.join(HOME,c)})

task :default do
	puts "Usage: rake all"
end

task :all => ["atom:link", "bash:link", "bash:cp_color", "git:link", "git:cp_config", "tmux:link", "vim:link", "vim:mkdir", "gem:link"]

namespace :atom do
	desc "Create symlink"
	task :link do
		symlink_ DIR_ATOM, File.join(HOME, ".atom") if OS =~ /^Darwin/
	end
end

namespace :bash do
	desc "Create symlink"
	task :link do
		org = File.join(HOME, ".bashrc")
		mv org, File.join(HOME, ".bashrc.org") if File.exist?(org) && !File.symlink?(org)

		org = File.join(HOME, ".bash_profile")
		mv org, File.join(HOME, ".bash_profile.org") if File.exist?(org) && !File.symlink?(org)

		same_name_symlinks DIR_BASH, ["bash_profile", "bashrc"]
	end

	task :cp_color => File.join(HOME, ".bash_color")
	desc "Create copy of .bash_color"
	file File.join(HOME, ".bash_color") do
		cp File.join(DIR_BASH,"bash_color"), File.join(HOME,".bash_color")
	end
end

namespace :git do
	desc "Create symlink"
	task :link do
		same_name_symlinks DIR_GIT, ["gitconfig", "gitignore.global"]
		# working here
	end

	task :cp_config => File.join(HOME,".gitconfig.local")
	desc "Create copy of .gitconfig.local"
	file File.join(HOME,".gitconfig.local") do
		cp File.join(DIR_GIT,"gitconfig.local"), File.join(HOME,".gitconfig.local")
	end
end

namespace :go do
	desc "create symlink in .vim"
	task :link do
		VIM_BUNDLE = File.join(DIR_VIM, "vim/bundle")
		case OS
		when /^Darwin/
			VIM_GO_SRC = "/usr/local/opt/go/libexec/misc/vim"
		when /^Linux/
			VIM_GO_SRC = "/usr/local/go/misc/vim"
		end
		symlink_ VIM_GO_SRC, File.join(VIM_BUNDLE, "go")
		
		GOCODE_SRC = File.join(HOME, "go/src/github.com/nsf/gocode/vim")
		symlink_ GOCODE_SRC, File.join(VIM_BUNDLE, "gocode")
	end

	desc "Run post install script"
	task :postinstall do
		sh "sh go/post_install.sh"
	end
end

namespace :tmux do
	desc "Create symlink"
	task :link do
		same_name_symlinks DIR_TMUX, ["tmux.conf"]
	end
end

namespace :vim do
	desc "Create symlink"
	task :link do
		same_name_symlinks DIR_VIM, ["vim", "vimrc", "vimrc_neocomplete"]
	end
	
	desc "Create ~/.vim_tmp"
	VIMTMP = File.join(HOME, ".vim_tmp")
	directory VIMTMP
	task :mkdir => VIMTMP do
	end
end

namespace :gem do
	desc "Create symlink"
	task :link do
		same_name_symlinks DIR_RUBY, ["gemrc"]
	end
end

def symlink_ file, dest
	begin
		# where is the code overriding FileUtils.symlink ?
		# FileUtils.symlink file, dest
		symlink file, dest
	rescue => ex
		puts ex.message
	end
end

def same_name_symlinks root, files
	files.each do |file|
		symlink_ File.join(root, file), File.join(HOME, "." + file)
	end
end
