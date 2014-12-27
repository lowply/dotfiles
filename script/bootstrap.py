#!/usr/bin/env python

import os.path
import datetime
import shutil
import fnmatch
import subprocess

home = os.environ["HOME"]
d = datetime.datetime.today().strftime("%y%m%d_%H%M%S")

colors = {
    "black"	:	"\033[30m",
    "red"	:	"\033[31m",
    "green"	:	"\033[32m",
    "yellow"	:	"\033[33m",
    "blue"	:	"\033[34m",
    "magenta"	:	"\033[35m",
    "cyan"	:	"\033[36m",
    "white"	:	"\033[37m",
    "rst"	:	"\033[39m",
}

def brackets(string, type, color):
    return "\t[" + colors[color] + type + colors["rst"] + "] " + string

def info (string):
    print(brackets(string, " >> ", "blue"))

def user (string):
    print(brackets(string, " ?? ", "yellow"))

def success (string):
    print(brackets(string, " OK ", "green"))

def fail (string):
    print(brackets(string, "FAIL", "red"))

def link_file(src, dst, copy):
    backupdir = home + "/dotfiles_backup_" + d
    if os.path.isfile(dst) or os.path.isdir(dst) or os.path.islink(dst):
        if not os.path.isdir(backupdir):
            os.mkdir(backupdir)
            success("Created " + backupdir)
        user ("%s is already exists: %s" % (dst, src))
        shutil.move(dst, backupdir)
        success ("Moved" + dst + " to " + backupdir)

    if copy:
        shutil.copy(src, dst)
        success ("Copied %s to %s" % (src, dst))
    else:
        os.symlink(src, dst)
        success ("Linked %s to %s" % (src, dst))

def install_dotfiles():
    os.chdir(os.path.abspath(os.path.dirname(__file__)))
    os.chdir(os.pardir)
    dotfiles_root = os.getcwd()

    info ("Installing dotfiles...")

    src = dotfiles_root + "/bash/bashrc.symlink"
    dst = home + "/." + os.path.basename(src).replace(".symlink","")

    # link_file(src, dst, False)
    for root, dirs, files in os.walk("."):
        for file in os.listdir(root):
            if fnmatch.fnmatch(file, '*.symlink'):
                print file


install_dotfiles()
