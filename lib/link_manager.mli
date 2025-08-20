(** Link Manager for symbolic link synchronization

   This module provides functionality for managing symbolic links between agent
   documentation files and the main guide file. It ensures that all agent files
   remain synchronized through symbolic link operations, providing atomic updates
   and preventing content drift. *)

(** Status of a link between an agent file and the main guide *)
type link_status =
  | ProperlyLinked of { target : string }
  (** Symbolic link to main guide with correct target path *)
  | NotLinked (** Regular file or doesn't exist - not linked to main guide *)
  | MissingFile (** File doesn't exist at the specified path *)
  | BrokenLink (** Points to wrong file or broken symlink *)

(** Information about a specific agent file link *)
type link_info =
  { agent_name : string (** Name of the agent (e.g., "claude", "gemini") *)
  ; agent_file : string (** Path to the agent file *)
  ; main_guide : string (** Path to the main guide file *)
  ; status : link_status (** Current status of the link *)
  }

(** Result of batch synchronization operations *)
type sync_result =
  { successful : string list
    (** List of agent names that were successfully synchronized *)
  ; failed : (string * string) list
    (** List of (agent_name, error_message) tuples for failed operations *)
  }

(** {1 Helper functions} *)

(** Check if a file exists at the given path *)
val file_exists : string -> bool

(** Write content to a file
    @param path File path to write to
    @param content Content to write
    @return Result indicating success or failure *)
val write_file_content : string -> string -> (unit, string) result

(** {1 Core operations} *)

(** Create a symbolic link from agent file to main guide
   @param main_guide Path to the main guide file
   @param agent_file Path to the agent file to link
   @return Result indicating success or failure *)
val create_link : main_guide:string -> agent_file:string -> (unit, string) result

(** Get comprehensive information about a specific agent file link
    @param agent_name Name of the agent
    @param agent_file Path to the agent file
    @param main_guide Path to the main guide file
    @return Complete link information *)
val get_link_info
  :  agent_name:string
  -> agent_file:string
  -> main_guide:string
  -> link_info

(** {1 Batch operations} *)

(** Check existing agent files against configuration
    @param config Configuration containing agent mappings
    @return List of (agent_name, error_message) for problematic files *)
val check_existing_agent_files : config:Config.t -> (string * string) list

(** Repair all broken links for agents in the configuration
    @param config Configuration containing agent mappings
    @return Sync result with successful and failed operations *)
val repair_all_links : config:Config.t -> sync_result

(** Synchronize all agent files with the main guide
    @param config Configuration containing agent mappings
    @return Sync result with successful and failed operations *)
val sync_all_links : config:Config.t -> sync_result
