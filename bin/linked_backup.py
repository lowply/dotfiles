#!/usr/bin/env python

"""
~/.backup.toml

backuproot = "/path/to/backup"
logdir     = "/path/to/logdir"
key        = "/path/to/ssh/key"

[[hosts]]
hostname   = "example.com"
term       = "7"
[[hosts.dirs]]
path       = "/home/username/"
excludes   = [".dein", ".cache", "dotfiles*"]
[[hosts.dirs]]
path       = "/home/username/"
excludes   = [".dein", ".cache", "dotfiles*"]

[[hosts]]
hostname   = "example.com"
term       = "7"
[[hosts.dirs]]
path       = "/home/username/"
excludes   = []
[[hosts.dirs]]
path       = "/home/username/"
excludes   = []
"""

import sys
import os
import os.path
import socket
import shutil
import time
import toml
import logging
import subprocess
from datetime import datetime, timedelta

now = datetime.now()
logpath = ""

def findlatest(path):
    os.chdir(path)
    return subprocess.check_output("ls -t", shell=True).decode("utf-8").split("\n")[0]

def loginit(backuproot):
    logdir = backuproot + "/log"
    if not os.path.isdir(logdir):
        os.mkdir(logdir)
    global logpath
    logpath = logdir + "/" + now.strftime("%y%m%d.%H%M%S") + ".log"
    logging.basicConfig(filename=logpath, level=logging.DEBUG, format='%(asctime)s: %(message)s', datefmt='%a, %d %b %Y %H:%M:%S +0000')

def checkconfig(config):
    for host in config["hosts"]:
        try:
            socket.gethostbyname(host["hostname"])
        except socket.gaierror as e:
            logging.error(str(e) + ": " + host["hostname"])
            return False
        return True

def readconfig():
    path = os.path.join(os.environ["HOME"], ".backup.toml")
    if not os.path.isfile(path):
        logging.error("Missing config file")
        sys.exit(1)

    with open(path) as file:
        config = toml.loads(file.read())

    if checkconfig(config):
        return config
    else:
        logging.error("Incorrect config file")
        sys.exit(1)

def dircheck(config):
    if not os.path.isdir(config["backuproot"]):
        os.mkdir(config["backuproot"])

    if not os.path.isdir(config["logdir"]):
        os.mkdir(config["logdir"])

def backup(key, backuproot, host):
    hostdir = backuproot + "/" + host["hostname"]
    datedir = hostdir + "/" + now.strftime("%y%m%d.%H%M%S")

    latestdir = findlatest(hostdir)

    if not os.path.isdir(datedir):
        os.makedirs(datedir)
        logging.info("Created directory: " + datedir)

    logging.info("Starting backup for " + host["hostname"] + " ...")

    for d in host["dirs"]:

        if not os.path.isdir(datedir + d["path"]):
            os.makedirs(datedir + d["path"])
            logging.info("Created directory: " + datedir + d["path"])

        excludes = ""
        for e in d["excludes"]:
            excludes += "--exclude='" + e + "' "
        cmd = ""
        cmd += "rsync -a --no-l "
        cmd += "--log-file=" + logpath + " "
        if latestdir:
            cmd += "--link-dest=" + hostdir + "/" + latestdir + d["path"] + " "
        cmd += excludes
        cmd += "-e 'ssh -i " + key + "' "
        cmd += host["hostname"] + ":" + d["path"] + " "
        cmd += datedir
        cmd += d["path"]
        cmd = cmd.strip()

        print(cmd)
        logging.info("Backup for " + d["path"] + " ...")
        logging.info("Running rsync command: " + cmd)
        try:
            subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            logging.error(e.output.decode('utf-8'))

    logging.info("Finished backup for " + host["hostname"])

def cleanup(backuproot, host):
    daysago = now - timedelta(days=int(host["term"]))
    backupdir = backuproot + "/" + host["hostname"]

    os.chdir(backupdir)
    for d in os.listdir():
        dirtime = datetime.fromtimestamp(os.path.getmtime(d))
        if (dirtime < daysago):
            shutil.rmtree(d)
            logging.info("Deleted old backup: " + backupdir + "/" + d)

def main():
    config = readconfig()
    loginit(config["backuproot"])
    dircheck(config)

    for host in config["hosts"]:
        backup(config["key"], config["backuproot"], host)
        cleanup(config["backuproot"], host)

main()
