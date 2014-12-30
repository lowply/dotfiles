#!/usr/bin/env python

import os.path
import datetime
import shutil
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
        user ("%s is already exists" %dst)
        shutil.move(dst, backupdir)
        success ("Moved" + dst + " to " + backupdir)

    if copy:
        shutil.copy(src, dst)
        success ("Copied %s to %s" % (src, dst))
    else:
        os.symlink(src, dst)
        success ("Linked %s to %s" % (src, dst))

def call(cmd):
    #
    # just a wrapper for subprocess.Popen, returns returncode, stdout, stderr
    #
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout_data, stderr_data = p.communicate()
    return p.returncode, stdout_data, stderr_data

def find(ext, tgt):
    #
    # search *.ext files in tgt and return result in a list format
    #
    arg = "find " + tgt + " -maxdepth 2 -name '*." + ext + "'"
    return call(arg)[1].splitlines()

def main():
    os.chdir(os.path.abspath(os.path.dirname(__file__)))
    os.chdir(os.pardir)
    dotfiles_root = os.getcwd()

    info ("Installing dotfiles...")

    for src in find("symlink", dotfiles_root):
        dst = home + "/." + os.path.basename(src).replace(".symlink","")
        link_file(src, dst, False)
        info("-" * 20)

    for src in find("copy", dotfiles_root):
        dst = home + "/." + os.path.basename(src).replace(".copy","")
        link_file(src, dst, True)
        info("-" * 20)

main()
