#!/usr/bin/env python3

"""

"""

import subprocess

class commander:
  def __init__(self):
    self.cmd  = None
    self.ret  = None

  def set_cmd(self, cmd:str):
    self.cmd = cmd

  def run(self):
    if not self.cmd:
      print(f"Command to run not specified")
      return 1

    print(f"Running command : \"{self.cmd}\"")
    self.ret = subprocess.run(
      self.cmd.split(),
      capture_output=True)

    return self.ret.returncode

  def get_output(self):
    return self.ret.stdout.decode("utf-8")

  def get_error(self):
    return self.ret.stderr.decode("utf-8")

