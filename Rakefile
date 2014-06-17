# coding: utf-8
require 'rake/clean'

#
# vars
#
HOME = ENV["HOME"]
OS = `uname`

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

#
# defs
#
def symlink_recursive root, files
	root_dir = File.join(File.dirname(__FILE__), root)
	files.each do |file|
		begin
			symlink File.join(root_dir, file), File.join(HOME, "." + file)
		rescue => ex
			puts ex.message
		end
	end
end

def copy_recursive root, files
	root_dir = File.join(File.dirname(__FILE__), root)
	files.each do |file|
		begin
			cp File.join(root_dir, file), File.join(HOME, "." + file)
		rescue => ex
			puts ex.message
		end
	end
end

#
# tasks
#
task :default do
	puts "Usage: rake all"
end

task :all => [
	"atom:link",
	"bash:link",
	"bash:copy",
	"git:link",
	"git:copy",
	"tmux:link",
	"vim:link",
	"vim:mkdir",
	"gem:link"
]

namespace :atom do
	desc "Create symlink only for OSX"
	task :link do
		symlink_recursive "atom", ["atom"] if OS =~ /^Darwin/
	end
end

namespace :bash do
	desc "Create symlink"
	task :link do
		org = File.join(HOME, ".bashrc")
		mv org, File.join(HOME, ".bashrc.org") if File.exist?(org) && !File.symlink?(org)

		org = File.join(HOME, ".bash_profile")
		mv org, File.join(HOME, ".bash_profile.org") if File.exist?(org) && !File.symlink?(org)

		symlink_recursive "bash", ["bash_profile", "bashrc"]
	end

	#
	# todo: how to avoid override copying
	#
	task :copy do
		copy_recursive "bash", ["bash_color"]
	end
end

namespace :git do
	desc "Create symlink"
	task :link do
		symlink_recursive "git", ["gitconfig", "gitignore.global"]
	end

	#
	# todo: how to avoid override copying
	#
	task :copy do
		copy_recursive "git", ["gitconfig.local"]
	end
end

namespace :tmux do
	desc "Create symlink"
	task :link do
		symlink_recursive "tmux", ["tmux.conf"]
	end
end

namespace :vim do
	desc "Create symlink"
	task :link do
		symlink_recursive "vim", ["vim", "vimrc", "vimrc_neocomplete"]
	end

	#
	# todo: can this be more simple?
	#
	desc "Create ~/.vim_tmp"
	VIMTMP = File.join(HOME, ".vim_tmp")
	directory VIMTMP
	task :mkdir => VIMTMP do
	end
end

namespace :gem do
	desc "Create symlink"
	task :link do
		symlink_recursive "ruby", ["gemrc"]
	end
end
