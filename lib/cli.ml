(** CLI module for agent-sync command-line interface *)

open Config
open Project
open Link_manager

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
    (* Load the created config and create initial symbolic links *)
    (match Config.load ~path:config_path () with
     | Error parse_error ->
       Printf.eprintf
         "Warning: Could not load created configuration: %s\n"
         (string_of_parse_error parse_error);
       0
     | Ok config ->
       (* Check for existing agent files that would be overwritten *)
       let existing_files = Link_manager.check_existing_agent_files ~config in
       if List.length existing_files > 0
       then (
         Printf.eprintf
           "Error: Found existing agent files with content that would be overwritten:\n";
         List.iter
           (fun (agent_name, agent_file) ->
              Printf.eprintf "  - %s: %s\n" agent_name agent_file)
           existing_files;
         Printf.eprintf
           "\nPlease backup these files or remove them before running init.\n";
         1)
       else (
         Printf.printf "Creating initial symbolic links...\n";
         let result = Link_manager.sync_all_links ~config in
         (* Show results *)
         if List.length result.successful > 0
         then (
           Printf.printf
             "Successfully created links for %d agents:\n"
             (List.length result.successful);
           List.iter (fun agent -> Printf.printf "  ✓ %s\n" agent) result.successful);
         if List.length result.failed > 0
         then (
           Printf.printf
             "Failed to create links for %d agents:\n"
             (List.length result.failed);
           List.iter
             (fun (agent, error) -> Printf.printf "  ✗ %s: %s\n" agent error)
             result.failed);
         0))
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
          (* Create the symbolic link *)
          (match
             Link_manager.create_link
               ~main_guide:updated_config.main_guide
               ~agent_file:filename
           with
           | Ok () ->
             Printf.printf "Added agent '%s' -> '%s'\n" agent filename;
             Printf.printf "Created symbolic link to main guide.\n";
             0
           | Error msg ->
             Printf.eprintf "Warning: Failed to create symbolic link: %s\n" msg;
             Printf.printf
               "Added agent '%s' -> '%s' (link creation failed)\n"
               agent
               filename;
             0)))
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
                | Some filename ->
                  let link_info =
                    Link_manager.get_link_info
                      ~agent_name:agent
                      ~agent_file:filename
                      ~main_guide:config.main_guide
                  in
                  let status_str =
                    match link_info.status with
                    | Link_manager.ProperlyLinked { target } ->
                      Printf.sprintf "✓ Linked (target: %s)" target
                    | Link_manager.NotLinked -> "✗ Not linked"
                    | Link_manager.MissingFile -> "✗ Missing file"
                    | Link_manager.BrokenLink -> "✗ Broken link"
                  in
                  Printf.printf "  %s -> %s [%s]\n" agent filename status_str
                | None -> ())
             agents;
         0))
;;

(** Repair agent files *)
let cmd_repair () =
  match Project.require_project () with
  | Error (System_error str) ->
    Printf.eprintf "Error: %s\n" str;
    Printf.eprintf "  Try `agent-sync init` to initialize a project.\n";
    1
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
       (* First, check if main_guide exists, create it if needed *)
       if not (Link_manager.file_exists config.main_guide)
       then (
         Printf.printf
           "Main guide file '%s' not found, creating empty file...\n"
           config.main_guide;
         match Link_manager.write_file_content config.main_guide "" with
         | Ok () -> Printf.printf "Created empty main guide file.\n"
         | Error msg ->
           Printf.eprintf "Failed to create main guide file: %s\n" msg;
           exit 1)
       else ();
       (* Check for existing agent files with content that would be overwritten *)
       let existing_files = Link_manager.check_existing_agent_files ~config in
       if List.length existing_files > 0
       then (
         Printf.eprintf
           "Error: Found existing agent files with content that would be overwritten:\n";
         List.iter
           (fun (agent_name, agent_file) ->
              Printf.eprintf "  - %s: %s\n" agent_name agent_file)
           existing_files;
         Printf.eprintf
           "\n\
            Please backup these files or manually merge their content before running \
            repair.\n";
         1)
       else (
         Printf.printf "Repairing agent file links...\n";
         let result = Link_manager.repair_all_links ~config in
         (* Show results *)
         if List.length result.successful > 0
         then (
           Printf.printf
             "Successfully repaired %d agents:\n"
             (List.length result.successful);
           List.iter (fun agent -> Printf.printf "  ✓ %s\n" agent) result.successful);
         if List.length result.failed > 0
         then (
           Printf.printf "Failed to repair %d agents:\n" (List.length result.failed);
           List.iter
             (fun (agent, error) -> Printf.printf "  ✗ %s: %s\n" agent error)
             result.failed);
         if List.length result.successful = 0 && List.length result.failed = 0
         then
           Printf.printf "No agents configured or all agents already properly linked.\n";
         0))
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
