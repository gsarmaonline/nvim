import random
import string
import hashlib


NVIM_SOCKET_FOLDER="/tmp/"
NVIM_SOCKET_FILE_NAME_PREFIX="nvim-socket"
NVIM_SOCKET_FILE_PREFIX=f"{NVIM_SOCKET_FOLDER}/{NVIM_SOCKET_FILE_NAME_PREFIX}"


def generate_random_str(count: int = 15) -> str:
    random_str: str = ''.join(random.choices(string.ascii_uppercase + string.digits, k=count))
    return random_str

def generate_uuid(base_str: str) -> str:
     return hashlib.md5(base_str.encode('utf-8')).hexdigest()


