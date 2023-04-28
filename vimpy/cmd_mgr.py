from typing import Any, Callable


class CommandAlreadyRegistered(Exception):
    pass


class CommandNotRegistered(Exception):
    pass


class CommandManager:
    def __init__(self):
        self.commands: dict[str, Any] = {}
        self._add_meta_commands()

    def _add_meta_commands(self):
        self.commands["help"] = {
            "func": lambda: self.all(),
            "desc": "Help command"
        }

    def add(self, command_name: str, func: Callable, desc: str = ""):
        if self.commands.get(command_name) is not None:
            raise CommandAlreadyRegistered

        self.commands[command_name] = {
            "func": func,
            "desc": desc
        }

    def show(self, command_name: str):
        if self.commands.get(command_name) is None:
            raise CommandNotRegistered
        return self.commands.get(command_name)

    def exec(self, command_name: str, cmd_args: list):
        cmd_obj = self.show(command_name)
        output = cmd_obj["func"](cmd_args)
        return output 

    def all(self) -> list:
        return list(self.commands.keys())
