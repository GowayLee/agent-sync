(** Configuration module interface for agent-sync *)

(** The main configuration type representing agent-sync settings *)
type t =
  { main_guide : string (** Path to the main AGENT_GUIDE.md file *)
  ; agents : (string * string) list
    (** List of agent name to filename mappings, e.g. [("claude", "CLAUDE.md")] *)
  }

(** Error type for configuration parsing operations *)
type parse_error =
  | File_not_found of string (** Configuration file not found at the specified path *)
  | Parse_error of string (** TOML parsing error with details *)
  | Missing_core_table (** Required [core] table missing from configuration *)
  | Missing_main_guide (** Required main_guide field missing from core table *)
  | Missing_agent_table (** Required [agents] table missing from configuration *)
  | Core_table_not_a_table (** [core] section exists but is not a table *)
  | Agents_table_not_a_table (** [agents] section exists but is not a table *)
  | Main_guide_not_a_string (** main_guide field exists but is not a string *)
  | Invalid_agent_mapping of string (** Agent mapping has invalid format or content *)

(** Convert configuration parse errors to user-friendly error messages.

    @param error The configuration parse error to convert
    @return User-friendly string description of the error *)
val string_of_parse_error : parse_error -> string

(** Load configuration from TOML file
    @param path Optional path to configuration file (defaults to ".agent-sync.toml")
    @return Configuration data or parse error *)
val load : ?path:string -> unit -> (t, parse_error) result

(** Error type for configuration saving operations *)
type save_error =
  | File_write_error of string * string
  (** File system error during write operation (path, error_message) *)
  | Encoding_error of string (** TOML encoding error with details *)

(** Convert configuration save errors to user-friendly error messages.

    @param error The configuration save error to convert
    @return User-friendly string description of the error *)
val string_of_save_error : save_error -> string

(** Save configuration to TOML file
    @param path Optional path to save configuration (defaults to ".agent-sync.toml")
    @param config Configuration data to save
    @return Unit or save error *)
val save : ?path:string -> t -> (unit, save_error) result

(** Create default configuration file with standard settings
    @return Unit or save error *)
val create_default : unit -> (unit, save_error) result

(** Get filename for a specific agent
    @param config Configuration data
    @param agent_name Name of the agent to look up
    @return Some filename if agent exists, None otherwise *)
val get_agent_filename : t -> string -> string option

(** List all configured agent names
    @param config Configuration data
    @return List of agent names in configuration *)
val list_agents : t -> string list

(** Add or update an agent mapping
    @param config Configuration data
    @param agent_name Name of the agent
    @param filename Filename for the agent documentation
    @return Updated configuration *)
val add_agent : t -> string -> string -> t

(** Default configuration filename *)
val config_file : string
