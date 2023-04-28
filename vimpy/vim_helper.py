from typing import Optional


class VimHelper:
    @classmethod
    def search_in_folder(cls, search_str: str, search_folder: Optional[str] = None) -> str:
        if search_folder is None:
            search_folder = "." 
        return (f"!Ack {search_str} {search_folder}")
