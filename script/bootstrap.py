#!/usr/bin/env python

import sys
import os.path
import datetime
import shutil
import subprocess

home = os.environ["HOME"]
d = datetime.datetime.today().strftime("%y%m%d_%H%M%S")
os.chdir(os.path.abspath(os.path.dirname(__file__)))
os.chdir(os.pardir)
dotfiles_root = os.getcwd()

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

def unlinkandremove():
    backupdir = home + "/dotfiles_backup_" + d
    if not os.path.isdir(backupdir):
        os.mkdir(backupdir)
        success("Created " + backupdir)

    info ("Cleaning up...")

    for src in find("symlink", dotfiles_root):
        src = home + "/." + os.path.basename(src).replace(".symlink","")
        if os.path.islink(src):
            os.remove(src)
            success (src + " has been unlinked.")

    for src in find("copy", dotfiles_root):
        src = home + "/." + os.path.basename(src).replace(".copy","")
        if os.path.isfile(src):
            shutil.move(src, backupdir)
            success ("Moved " + src + " to " + backupdir)

    vim_tmp = home + "/.vim_tmp"
    if os.path.isdir(vim_tmp):
        shutil.rmtree(vim_tmp)
        success (vim_tmp + " has been removed.")

def linkandcopy():
    info ("Installing dotfiles...")

    for src in find("symlink", dotfiles_root):
        dst = home + "/." + os.path.basename(src).replace(".symlink","")
        link_file(src, dst, False)

    for src in find("copy", dotfiles_root):
        dst = home + "/." + os.path.basename(src).replace(".copy","")
        link_file(src, dst, True)

    vim_tmp = home + "/.vim_tmp"
    if not os.path.isdir(vim_tmp):
        os.mkdir(vim_tmp)
        success ("Create ~/.vim_tmp")

    print("\nDon't forget to setup your ~/.gitconfig.local below")
    print("----------------------------------------")
    print(call("cat ~/.gitconfig.local")[1])

def main(args):
    if len(args) == 1:
        linkandcopy()
    elif len(args) == 2:
        if args[1] == "clean":
            unlinkandremove()
        else:
            print ("Unknown argument. Usage: ./bootstrap.py | ./bootstrap.py clean")
    elif len(args) > 2:
        print ("Too many arguments. Usage: ./bootstrap.py | ./bootstrap.py clean")

main(sys.argv)
