(** Registry module for system-wide agent-sync project management *)

(** Information about a single agent in a project *)
type agent_info =
  { name : string (** Name of the agent (e.g., "claude", "gemini") *)
  ; file : string (** Path to the agent's documentation file *)
  }

(** Complete information about a registered project *)
type project_info =
  { directory : string (** Absolute path to the project root directory *)
  ; main_guide : string (** Path to the main guide file within the project *)
  ; agents : agent_info list (** List of agents configured for this project *)
  }

(** Possible errors that can occur during registry operations *)
type registry_error =
  | File_not_found of string (** Registry file not found at specified path *)
  | Parse_error of string (** Failed to parse registry file content *)
  | Write_error of string * string (** Failed to write to registry file (path, error) *)
  | Invalid_registry_format of string (** Registry file has invalid format *)
  | System_error of string (** System-level error during operation *)

(** Register the current project in the system-wide registry.

    This function detects the current project, reads its configuration,
    and adds it to the system registry for tracking across the system.

    @return [Ok ()] if registration succeeds, [Error err] with details if it fails
*)
val register_current_project : unit -> (unit, registry_error) result

(** Display all projects registered in the system-wide registry.

    This function reads the registry and shows information about all
    tracked projects, including their locations and configured agents.

    @return [Ok ()] if display succeeds, [Error err] if registry access fails
*)
val show_all_projects : unit -> (unit, registry_error) result

(** Convert a registry error to a human-readable string for display.

    @param err The registry error to convert
    @return String description of the error suitable for user display
*)
val string_of_registry_error : registry_error -> string
