(** Convert project errors to user-friendly error messages.

    @param error The project error to convert
    @return User-friendly string description of the error *)
val string_of_project_error : Project.error -> string

(** Convert configuration parse errors to user-friendly error messages.

    @param error The configuration parse error to convert
    @return User-friendly string description of the error *)
val string_of_parse_error : Config.parse_error -> string

(** Convert configuration save errors to user-friendly error messages.

    @param error The configuration save error to convert
    @return User-friendly string description of the error *)
val string_of_save_error : Config.save_error -> string

(** Initialize a new agent-sync project in the current directory.

    Creates a default .agent-sync.toml configuration file with
    standard settings. Returns 0 on success, 1 on failure.

    @return Exit code (0 for success, 1 for error) *)
val cmd_init : unit -> int

(** Add a new agent mapping to the current project configuration.

    Adds a new agent entry to the [agents] table in the configuration file.
    Note: hard link creation is not yet implemented.

    @param agent The agent name (e.g., "claude", "gemini")
    @param filename The target filename for the agent (e.g., "CLAUDE.md")
    @return Exit code (0 for success, 1 for error) *)
val cmd_add : string -> string -> int

(** Show status of agent-sync project(s).

    When [all] is false, shows status of the current project including
    project root, main guide, and configured agents.
    When [all] is true, shows all registered projects (not yet implemented).

    @param all Whether to show all projects or just current project
    @return Exit code (0 for success, 1 for error) *)
val cmd_status : bool -> int

(** Repair broken agent file links.

    This command will check and repair hard links between agent files
    and the main guide. Currently not implemented.

    @return Exit code (0 for success, 1 for error) *)
val cmd_repair : unit -> int

(** Display help information about agent-sync commands.

    Shows usage instructions, available commands, and examples.

    @return Exit code (always 0) *)
val cmd_help : unit -> int

(** Main CLI entry point that parses and executes commands.

    Parses command line arguments and dispatches to appropriate
    command functions. Handles unknown commands and shows help
    when no command is provided.

    @param args Command line arguments (including program name)
    @return Exit code (0 for success, 1 for error) *)
val run : string array -> int
