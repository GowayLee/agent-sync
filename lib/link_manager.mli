(** Link Manager for hard link synchronization *)

type link_status =
  | ProperlyLinked of { inode : int } (* Hard link to main guide *)
  | NotLinked (* Regular file or doesn't exist *)
  | MissingFile (* File doesn't exist *)
  | BrokenLink (* Points to wrong file *)

type link_info =
  { agent_name : string
  ; agent_file : string
  ; main_guide : string
  ; status : link_status
  }

type sync_result =
  { successful : string list
  ; failed : (string * string) list (* (agent_name, error_message) *)
  }

(** Create a hard link from main_guide to agent_file *)
val create_link : main_guide:string -> agent_file:string -> (unit, string) result

(** Check if agent_file is properly linked to main_guide *)
val check_link : main_guide:string -> agent_file:string -> link_status

(** Repair broken link by merging content and recreating link *)
val repair_link : main_guide:string -> agent_file:string -> (unit, string) result

(** Remove agent file if it's a link *)
val remove_link : agent_file:string -> (unit, string) result

(** Synchronize all configured agent links *)
val sync_all_links : config:Config.t -> sync_result

(** Check for existing agent files with content that would be overwritten *)
val check_existing_agent_files : config:Config.t -> (string * string) list

(** Repair all configured agent links *)
val repair_all_links : config:Config.t -> sync_result

(** Get detailed information about a link *)
val get_link_info
  :  agent_name:string
  -> agent_file:string
  -> main_guide:string
  -> link_info
