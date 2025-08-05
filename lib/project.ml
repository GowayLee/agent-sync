(** Project module for detecting project directories and finding config files *)

type t =
  { root : string
  ; config_path : string
  }

type error =
  | Not_in_project
  | Config_not_found of string
  | Permission_denied of string
  | System_error of string

let config_file = Config.config_file

let rec find_project_root current_dir =
  if current_dir = "/"
  then None
  else (
    let config_path = Filename.concat current_dir config_file in
    if Sys.file_exists config_path
    then Some current_dir
    else find_project_root (Filename.dirname current_dir))
;;

let get_current_dir () =
  try Ok (Sys.getcwd ()) with
  | Sys_error msg -> Error (System_error msg)
;;

let detect_project () =
  match get_current_dir () with
  | Error e -> Error e
  | Ok current_dir ->
    (match find_project_root current_dir with
     | Some root ->
       let config_path = Filename.concat root config_file in
       Ok { root; config_path }
     | None -> Error Not_in_project)
;;

let is_project_dir dir =
  let config_path = Filename.concat dir config_file in
  Sys.file_exists config_path
;;

let find_config_in_cwd () =
  match get_current_dir () with
  | Error e -> Error e
  | Ok current_dir ->
    let config_path = Filename.concat current_dir config_file in
    if Sys.file_exists config_path
    then Ok config_path
    else Error (Config_not_found config_path)
;;

let get_project_info () =
  match detect_project () with
  | Error e -> Error e
  | Ok project -> Ok project
;;

let get_relative_path project path =
  if Filename.is_relative path
  then path
  else (
    try
      let rel_path = Filename.concat project.root path in
      Filename.current_dir_name ^ "/" ^ rel_path
    with
    | _ -> path)
;;

let absolute_path project path =
  if String.length path > 0 && path.[0] = '/'
  then path
  else Filename.concat project.root path
;;

let validate_project project =
  if not (Sys.file_exists project.config_path)
  then Error (Config_not_found project.config_path)
  else if not (is_project_dir project.root)
  then Error Not_in_project
  else Ok project
;;

let require_project () =
  match get_project_info () with
  | Ok project -> Ok project
  | Error Not_in_project -> Error (System_error "Not in an agent-sync project directory")
  | Error e -> Error e
;;

let create_project_config () =
  match get_current_dir () with
  | Error e -> Error e
  | Ok current_dir ->
    let config_path = Filename.concat current_dir config_file in
    if Sys.file_exists config_path
    then Error (System_error "Config file already exists")
    else (
      match Config.create_default () with
      | Ok () -> Ok config_path
      | Error (Config.File_write_error (path, msg)) ->
        Error
          (System_error (Printf.sprintf "Failed to write config file: %s: %s" path msg))
      | Error (Config.Encoding_error msg) ->
        Error (System_error (Printf.sprintf "Failed to encode config: %s" msg)))
;;
