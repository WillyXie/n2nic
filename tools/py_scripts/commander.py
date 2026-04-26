#!/usr/bin/env python3

"""

"""

import subprocess
import os

class commander:
  def __init__(self):
    self.cmd  = None
    self.ret  = None
    self.envs = {}

  def set_cmd(self, cmd:str):
    self.cmd = cmd

  def set_env(self, key:str, value:str):
    self.envs[key] = value

  def run(self):
    if not self.cmd:
      print(f"Command to run not specified")
      return 1

    my_env = os.environ.copy()
    for (key,value) in self.envs.items():
      my_env[key] = value

    print(f"Running command : \"{self.cmd}\"")
    self.ret = subprocess.run(
      self.cmd.split(),
      env=my_env,
      #capture_output=True,
      stdout=subprocess.PIPE,
      stderr=subprocess.STDOUT,
      text=True)

    if self.ret:
      print(f"Error: {self.ret.stdout}")
    else:
      print(f"{self.ret.stdout}")

    return self.ret.returncode

  def get_output(self):
    #return self.ret.stdout.decode("utf-8")
    return self.ret.stdout

  def get_error(self):
    #return self.ret.stderr.decode("utf-8")
    return self.ret.stderr

