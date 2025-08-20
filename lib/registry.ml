(** Registry module for system-wide agent-sync project management *)

type agent_info =
  { name : string
  ; file : string
  }

type project_info =
  { directory : string
  ; main_guide : string
  ; agents : agent_info list
  }

type registry = { projects : project_info list }

type registry_error =
  | File_not_found of string
  | Parse_error of string
  | Write_error of string * string
  | Invalid_registry_format of string
  | System_error of string

(** Convert registry error to user-friendly message *)
let string_of_registry_error = function
  | File_not_found path -> Printf.sprintf "File not found: %s" path
  | Parse_error msg -> Printf.sprintf "Parse error: %s" msg
  | Write_error (path, msg) -> Printf.sprintf "Write error to %s: %s" path msg
  | Invalid_registry_format msg -> Printf.sprintf "Invalid format: %s" msg
  | System_error msg -> Printf.sprintf "System error: %s" msg
;;

let registry_file =
  let home = Sys.getenv "HOME" in
  Filename.concat home ".agent-sync.json"
;;

(** Convert agent_info to Yojson *)
let agent_info_to_json (agent : agent_info) : Yojson.Safe.t =
  `Assoc [ "name", `String agent.name; "file", `String agent.file ]
;;

(** Convert project_info to Yojson *)
let project_info_to_json (project : project_info) : Yojson.Safe.t =
  `Assoc
    [ "directory", `String project.directory
    ; "main_guide", `String project.main_guide
    ; "agents", `List (List.map agent_info_to_json project.agents)
    ]
;;

(** Convert registry to Yojson *)
let registry_to_json (registry : registry) : Yojson.Safe.t =
  `Assoc [ "projects", `List (List.map project_info_to_json registry.projects) ]
;;

(** Parse agent_info from Yojson *)
let agent_info_of_json (json : Yojson.Safe.t) : (agent_info, string) result =
  match json with
  | `Assoc assoc ->
    let name =
      try Some (List.assoc "name" assoc) with
      | Not_found -> None
    in
    let file =
      try Some (List.assoc "file" assoc) with
      | Not_found -> None
    in
    (match name, file with
     | Some (`String n), Some (`String f) -> Ok { name = n; file = f }
     | Some (`String _), Some _ -> Error "file field must be a string"
     | Some _, Some (`String _) -> Error "name field must be a string"
     | Some (`String _), None -> Error "Missing required field: file"
     | None, Some (`String _) -> Error "Missing required field: name"
     | None, None -> Error "Missing required fields: name, file"
     | Some _, None -> Error "Missing required field: file"
     | None, Some _ -> Error "Missing required field: name"
     | Some _, Some _ -> Error "Invalid types for name or file fields")
  | `String _ | `Int _ | `Intlit _ | `Float _ | `Bool _ | `Null | `List _ ->
    Error "Agent info must be a JSON object"
;;

(** Parse project_info from Yojson *)
let project_info_of_json (json : Yojson.Safe.t) : (project_info, string) result =
  match json with
  | `Assoc assoc ->
    let directory =
      try Some (List.assoc "directory" assoc) with
      | Not_found -> None
    in
    let main_guide =
      try Some (List.assoc "main_guide" assoc) with
      | Not_found -> None
    in
    let agents =
      try Some (List.assoc "agents" assoc) with
      | Not_found -> None
    in
    (match directory, main_guide, agents with
     | Some (`String d), Some (`String mg), Some (`List agents_list) ->
       let agents_result = List.map agent_info_of_json agents_list in
       let valid_agents =
         List.filter
           (function
             | Ok _ -> true
             | Error _ -> false)
           agents_result
       in
       let agent_errors =
         List.filter_map
           (function
             | Error e -> Some e
             | Ok _ -> None)
           agents_result
       in
       if List.length agent_errors > 0
       then Error (String.concat "; " agent_errors)
       else (
         let agents =
           List.map
             (function
               | Ok a -> a
               | Error _ -> assert false)
             valid_agents
         in
         Ok { directory = d; main_guide = mg; agents })
     | Some (`String _), Some (`String _), Some (`String _) ->
       assert false (* unreachable *)
     | Some (`String _), Some (`String _), Some _ -> Error "agents field must be a list"
     | Some (`String _), Some (`String _), None -> assert false (* unreachable *)
     | Some (`String _), Some _, None -> Error "main_guide field must be a string"
     | Some (`String _), None, _ -> Error "Missing required field: main_guide"
     | Some _, Some (`String _), None -> Error "directory field must be a string"
     | Some _, None, _ -> Error "Missing required field: directory"
     | None, _, _ -> Error "Missing required field: directory"
     | _ -> Error "Invalid types for directory, main_guide, or agents fields")
  | `String _ | `Int _ | `Intlit _ | `Float _ | `Bool _ | `Null | `List _ ->
    Error "Project info must be a JSON object"
;;

(** Parse registry from Yojson *)
let registry_of_json (json : Yojson.Safe.t) : (registry, string) result =
  match json with
  | `Assoc assoc ->
    let projects =
      try Some (List.assoc "projects" assoc) with
      | Not_found -> None
    in
    (match projects with
     | Some (`List projects_list) ->
       let projects_result = List.map project_info_of_json projects_list in
       let valid_projects =
         List.filter
           (function
             | Ok _ -> true
             | Error _ -> false)
           projects_result
       in
       let project_errors =
         List.filter_map
           (function
             | Error e -> Some e
             | Ok _ -> None)
           projects_result
       in
       if List.length project_errors > 0
       then Error (String.concat "; " project_errors)
       else (
         let projects =
           List.map
             (function
               | Ok p -> p
               | Error _ -> assert false)
             valid_projects
         in
         Ok { projects })
     | Some (`String _) -> assert false (* unreachable *)
     | Some _ -> Error "Projects field must be a list"
     | None -> Error "Missing required field: projects")
  | `String _ | `Int _ | `Intlit _ | `Float _ | `Bool _ | `Null | `List _ ->
    Error "Registry must be a JSON object"
;;

(** Empty registry *)
let empty_registry = { projects = [] }

(** Load registry from file *)
let load_registry () : (registry, registry_error) result =
  try
    let content = In_channel.with_open_text registry_file In_channel.input_all in
    let json = Yojson.Safe.from_string content in
    match registry_of_json json with
    | Ok registry -> Ok registry
    | Error msg -> Error (Invalid_registry_format msg)
  with
  | Sys_error msg when String.ends_with ~suffix:"No such file or directory" msg ->
    (* Registry file doesn't exist yet, return empty registry *)
    Ok empty_registry
  | Sys_error msg -> Error (System_error msg)
  | exn -> Error (Parse_error (Printexc.to_string exn))
;;

(** Save registry to file *)
let save_registry (registry : registry) : (unit, registry_error) result =
  try
    (* Ensure parent directory exists *)
    let parent_dir = Filename.dirname registry_file in
    if not (Sys.file_exists parent_dir) then Unix.mkdir parent_dir 0o755;
    let json = registry_to_json registry in
    let content = Yojson.Safe.pretty_to_string json in
    Out_channel.with_open_text registry_file (fun oc -> output_string oc content);
    Ok ()
  with
  | Unix.Unix_error (Unix.EEXIST, _, _) ->
    (* Directory already exists, continue with file creation *)
    let json = registry_to_json registry in
    let content = Yojson.Safe.pretty_to_string json in
    Out_channel.with_open_text registry_file (fun oc -> output_string oc content);
    Ok ()
  | Unix.Unix_error (Unix.EACCES, _, _) ->
    Error (Write_error (registry_file, "Permission denied"))
  | Unix.Unix_error (code, _, _) ->
    Error (Write_error (registry_file, Unix.error_message code))
  | Sys_error msg -> Error (Write_error (registry_file, msg))
  | exn -> Error (System_error (Printexc.to_string exn))
;;

(** Add or update a project in the registry *)
let add_or_update_project (registry : registry) (project : project_info) : registry =
  let existing_projects =
    List.filter (fun p -> p.directory <> project.directory) registry.projects
  in
  { projects = project :: existing_projects }
;;

(** Check if a project directory still has a valid config file - use Project.is_project_dir *)
let project_has_valid_config (project : project_info) : bool =
  Project.is_project_dir project.directory
;;

(** Validate all projects in the registry, removing those without valid config files *)
let validate_projects (registry : registry) : registry =
  { projects = List.filter project_has_valid_config registry.projects }
;;

(** Get all projects from registry *)
let get_all_projects (registry : registry) : project_info list = registry.projects

(** Convert Project.t and Config.t to project_info for registry *)
let create_project_info (project : Project.t) (config : Config.t) : project_info =
  let agents = List.map (fun (name, file) -> { name; file }) config.agents in
  { directory = project.root; main_guide = config.main_guide; agents }
;;

(** Register current project in registry with error handling *)
let register_current_project () : (unit, registry_error) result =
  match Project.require_project () with
  | Error _ -> Error (System_error "Not in a valid project directory")
  | Ok project ->
    let config_path = project.config_path in
    (match Config.load ~path:config_path () with
     | Error _ -> Error (System_error "Failed to load project configuration")
     | Ok config ->
       let project_info = create_project_info project config in
       (match load_registry () with
        | Error err -> Error err
        | Ok registry ->
          let updated_registry = add_or_update_project registry project_info in
          save_registry updated_registry))
;;

(** Show all registered projects with validation *)
let show_all_projects () : (unit, registry_error) result =
  match load_registry () with
  | Error err -> Error err
  | Ok registry ->
    (* Ensure registry file exists by saving empty registry if needed *)
    (match save_registry registry with
     | Error err -> Error err
     | Ok () ->
       let validated_registry = validate_projects registry in
       (* Update the registry file with only validated projects *)
       (match save_registry validated_registry with
        | Error err -> Error err
        | Ok () ->
          let projects = get_all_projects validated_registry in
          if List.length projects = 0
          then (
            Printf.printf "No agent-sync projects found in registry.\n";
            Ok ())
          else (
            Printf.printf "Found %d agent-sync projects:\n\n" (List.length projects);
            List.iteri
              (fun i registry_project ->
                 Printf.printf "%d. %s\n" (i + 1) registry_project.directory;
                 Printf.printf "   Main guide: %s\n" registry_project.main_guide;
                 Printf.printf
                   "   Agents: %s\n"
                   (String.concat
                      ", "
                      (List.map (fun a -> a.name) registry_project.agents));
                 Printf.printf
                   "   Status: %s\n"
                   (if project_has_valid_config registry_project
                    then "✓ Valid"
                    else "✗ Invalid (config missing)");
                 Printf.printf "\n")
              projects;
            Ok ())))
;;
