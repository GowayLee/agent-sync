(** CLI module for agent-sync command-line interface *)

open Config
open Project

(** Convert project errors to user-friendly messages *)
let string_of_project_error = function
  | Not_in_project -> "Not in an agent-sync project directory"
  | Config_not_found path -> Printf.sprintf "Configuration file not found: %s" path
  | Permission_denied msg -> Printf.sprintf "Permission denied: %s" msg
  | System_error msg -> Printf.sprintf "System error: %s" msg
;;

(** Convert config parse errors to user-friendly messages *)
let string_of_parse_error = function
  | File_not_found path -> Printf.sprintf "Configuration file not found: %s" path
  | Parse_error msg -> Printf.sprintf "Configuration parse error: %s" msg
  | Missing_core_table -> "Missing required [core] table in configuration"
  | Missing_main_guide -> "Missing required 'main_guide' field in [core] table"
  | Missing_agent_table -> "Missing required [agents] table in configuration"
  | Core_table_not_a_table -> "[core] section exists but is not a valid table"
  | Agents_table_not_a_table -> "[agents] section exists but is not a valid table"
  | Main_guide_not_a_string -> "'main_guide' field must be a string"
  | Invalid_agent_mapping msg -> Printf.sprintf "Invalid agent mapping: %s" msg
;;

(** Convert config save errors to user-friendly messages *)
let string_of_save_error = function
  | File_write_error (path, msg) -> Printf.sprintf "Failed to write file %s: %s" path msg
  | Encoding_error msg -> Printf.sprintf "Configuration encoding error: %s" msg
;;

(** Initialize a new agent-sync project *)
let cmd_init () =
  match Project.create_project_config () with
  | Ok config_path ->
    Printf.printf "Created agent-sync configuration: %s\n" config_path;
    0
  | Error error ->
    Printf.eprintf "Failed to initialize project: %s\n" (string_of_project_error error);
    1
;;

(** Add a new agent to the configuration *)
let cmd_add agent filename =
  match Project.require_project () with
  | Error error ->
    Printf.eprintf "Error: %s\n" (string_of_project_error error);
    1
  | Ok project ->
    let config_path = project.config_path in
    (match Config.load ~path:config_path () with
     | Error parse_error ->
       Printf.eprintf "Configuration error: %s\n" (string_of_parse_error parse_error);
       1
     | Ok config ->
       let updated_config = Config.add_agent config agent filename in
       (match Config.save ~path:config_path updated_config with
        | Error save_error ->
          Printf.eprintf
            "Failed to save configuration: %s\n"
            (string_of_save_error save_error);
          1
        | Ok () ->
          Printf.printf "Added agent '%s' -> '%s'\n" agent filename;
          Printf.printf
            "Note: Hard link creation will be implemented in a future version.\n";
          0))
;;

(** Show status of current project *)
let cmd_status all =
  if all
  then (
    Printf.eprintf "System-wide project listing is not yet implemented.\n";
    Printf.eprintf "This feature requires the Registry module.\n";
    1)
  else (
    match Project.require_project () with
    | Error error ->
      Printf.eprintf "Error: %s\n" (string_of_project_error error);
      1
    | Ok project ->
      let config_path = project.config_path in
      (match Config.load ~path:config_path () with
       | Error parse_error ->
         Printf.eprintf "Configuration error: %s\n" (string_of_parse_error parse_error);
         1
       | Ok config ->
         Printf.printf "Project: %s\n" project.root;
         Printf.printf "Main guide: %s\n" config.main_guide;
         Printf.printf "Configured agents:\n";
         let agents = Config.list_agents config in
         if List.length agents = 0
         then Printf.printf "  No agents configured\n"
         else
           List.iter
             (fun agent ->
                match Config.get_agent_filename config agent with
                | Some filename -> Printf.printf "  %s -> %s\n" agent filename
                | None -> ())
             agents;
         0))
;;

(** Repair agent files (placeholder implementation) *)
let cmd_repair () =
  Printf.eprintf "Link repair is not yet implemented.\n";
  Printf.eprintf "This feature requires the LinkManager module.\n";
  1
;;

(** Show help *)
let cmd_help () =
  Printf.printf "Agent-sync: Unified agent document management\n\n";
  Printf.printf "USAGE:\n";
  Printf.printf "  agent-sync <COMMAND>\n\n";
  Printf.printf "COMMANDS:\n";
  Printf.printf "  init      Initialize a new agent-sync project\n";
  Printf.printf "  add       Add a new agent file mapping\n";
  Printf.printf "  status    Show agent-sync status\n";
  Printf.printf "  repair    Repair broken agent file links\n";
  Printf.printf "  help      Show this help message\n\n";
  Printf.printf "EXAMPLES:\n";
  Printf.printf "  agent-sync init                    # Initialize in current directory\n";
  Printf.printf "  agent-sync add copilot COPILOT.md  # Add copilot agent\n";
  Printf.printf "  agent-sync status                  # Show current status\n";
  Printf.printf
    "  agent-sync status --all            # Show all projects (not implemented)\n";
  0
;;

(** Main CLI entry point *)
let run args =
  match Array.to_list args with
  | _ :: [] -> cmd_help ()
  | [ _; "init" ] -> cmd_init ()
  | [ _; "add"; agent; filename ] -> cmd_add agent filename
  | [ _; "status" ] -> cmd_status false
  | [ _; "status"; "--all" ] -> cmd_status true
  | [ _; "repair" ] -> cmd_repair ()
  | [ _; "help" ] -> cmd_help ()
  | _ :: cmd :: _ ->
    Printf.eprintf "Unknown command: %s\n" cmd;
    Printf.eprintf "Use 'agent-sync help' for usage information.\n";
    1
  | _ -> cmd_help ()
;;
