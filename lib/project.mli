(** Project detection and management module.

    This module provides functionality for detecting agent-sync project directories,
    finding configuration files, and managing project paths. It handles the logic
    of locating project roots by searching for .agent-sync.toml files and provides
    utilities for working with project-relative paths. *)

(** Project information containing root directory and config file path *)
type t =
  { root : string
  ; config_path : string
  }

(** Possible errors that can occur during project operations *)
type error =
  | Not_in_project (** Current directory is not within an agent-sync project *)
  | Config_not_found of string (** Configuration file not found at the specified path *)
  | Permission_denied of string (** Permission denied when accessing file or directory *)
  | System_error of string (** General system error occurred *)

(** Convert project errors to user-friendly error messages.

    @param error The project error to convert
    @return User-friendly string description of the error *)
val string_of_project_error : error -> string

(** Check if a directory is an agent-sync project root.

    @param dir Directory path to check
    @return [true] if directory contains a config file, [false] otherwise *)
val is_project_dir : string -> bool

(** Validate that a project structure is correct.

    Checks that the config file exists and the root directory is a valid project.

    @param project Project to validate
    @return [Ok project] if valid, [Error error] if validation fails *)
val validate_project : t -> (t, error) result

(** Require being in an agent-sync project directory.

    Similar to [detect_project()] but provides a more specific error message
    when not in a project directory.

    @return [Ok project] if in project, [Error error] otherwise *)
val require_project : unit -> (t, error) result

(** Create a default project configuration file in the current directory.

    Creates a new .agent-sync.toml file with default configuration.
    Fails if the config file already exists.

    @return [Ok config_path] if created successfully, [Error error] if creation fails *)
val create_project_config : unit -> (string, error) result
