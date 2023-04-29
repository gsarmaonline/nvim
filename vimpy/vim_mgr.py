import os
import sys
import subprocess

from common import NVIM_SOCKET_FILE_PREFIX, generate_random_str, generate_uuid


class VimManager:
    def __init__(self, *args, **kwargs):
        self.uuid: str = generate_random_str() 
        self.curr_folder: str = kwargs.get("curr_folder", os.getcwd()) 
        self.curr_folder_hash: str = generate_uuid(base_str=self.curr_folder)

    def _start_nvim(self) -> None:
        nvim_socket_path: str = f"{NVIM_SOCKET_FILE_PREFIX}-{self.curr_folder_hash}-{self.uuid}"
        nvim_socket_env: str = os.environ.copy()
        nvim_socket_env.update({
            "NVIM_LISTEN_ADDRESS": nvim_socket_path
        })
        os.chdir(self.curr_folder)
        process = subprocess.run(["nvim"], shell=True, env=nvim_socket_env)

    def start(self) -> None:
        self._start_nvim()


if __name__ == "__main__":
    curr_folder: str = os.getcwd()
    if len(sys.argv) > 1:
        curr_folder = sys.argv[1]
    vim_mgr: "VimManager" = VimManager(curr_folder=curr_folder)
    vim_mgr.start()
