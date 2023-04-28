import json
import os
import sys
import pynvim
from pynvim import attach
from cmd_mgr import CommandManager
from vim_helper import VimHelper
from typing import Optional

TERM_LINE_PREFIX = ">> "


class Vimpy:
    def __init__(self, *args, **kwargs):
        self.curr_folder: str = kwargs.get("curr_folder", os.getcwd())
        self.socket: str = self._get_socket_for_folder() 

        self.nvim = attach('socket', path=self.socket)
        self.cmd_mgr: "CommandManager" = CommandManager()
        self.vim_helper: "VimHelper" = VimHelper()

        self._add_commands()

    def _get_socket_for_folder(self) -> str:
        socket_path: str = "/tmp/nvim-socket"
        # TODO: Insert logic to iterate through sockets prefixed with curr_folder hash
        return socket_path

    def _add_commands(self):
        self.cmd_mgr.add("get_windows", self._get_curr_windows)
        self.cmd_mgr.add("get_curr_buffer", self._get_curr_buffer)
        self.cmd_mgr.add("search", self._search)

    def _get_curr_folder(self) -> str:
        # TODO: Get curr folder of the buffer
        return "app"

    def _search(self, search_args: list):
        search_folder: Optional[str] = None
        search_str: str = search_args[0]
        if len(search_args) >= 2:
            search_folder = search_args[1]
        if not search_folder:
            search_folder = self._get_curr_folder()
        search_cmd: str = self.vim_helper.search_in_folder(search_str, search_folder)
        return self._run_command(search_cmd)

    def _get_curr_buffer(self):
        return self.nvim.current.buffer

    def _get_curr_windows(self):
        return self.nvim.windows

    def _run_command(self, command: str, *args, **kwargs):
        print(command)
        self.nvim.command(command)

    def _start_inp_loop(self):
        while True:
            try:
                print(TERM_LINE_PREFIX, end='')
                inp: str = input()
                cmd: str = inp.split(" ")[0]
                cmd_args: list = inp.split(" ")[1:]
                output = self.cmd_mgr.exec(cmd, cmd_args)
                print(output)
            except Exception as e:
                print(e)

    def run(self):
        self._start_inp_loop()


if __name__ == "__main__":
    curr_folder: str = sys.argv[1]
    print(f"Starting VimPy CLI on {curr_folder}")
    vimpy: "Vimpy" = Vimpy(curr_folder=curr_folder)
    vimpy.run()
