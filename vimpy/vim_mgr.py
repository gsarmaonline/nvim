import os
import sys
import subprocess
import random
import string
import hashlib


class VimManager:
    def __init__(self, *args, **kwargs):
        self.uuid: str = self._generate_random_str() 
        self.curr_folder: str = kwargs.get("curr_folder", os.getcwd()) 
        self.curr_folder_hash: str = hashlib.md5(self.curr_folder.encode('utf-8')).hexdigest()

    def _generate_random_str(self) -> str:
        random_str: str = ''.join(random.choices(string.ascii_uppercase + string.digits, k=15))
        return random_str

    def _start_nvim(self) -> None:
        nvim_socket_path: str = f"/tmp/nvim-socket-{self.curr_folder_hash}-{self.uuid}"
        nvim_socket_env: str = os.environ.copy()
        nvim_socket_env.update({
            "NVIM_LISTEN_ADDRESS": nvim_socket_path
        })
        os.chdir(self.curr_folder)
        process = subprocess.run(["nvim"], shell=True, env=nvim_socket_env)

    def start(self) -> None:
        self._start_nvim()


if __name__ == "__main__":
    vim_mgr: "VimManager" = VimManager(curr_folder=sys.argv[1])
    vim_mgr.start()
