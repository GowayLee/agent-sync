(** Link Manager for hard link synchronization *)

type link_status =
  | ProperlyLinked of { target : string } (* Symlink to main guide *)
  | NotLinked (* Regular file or doesn't exist *)
  | MissingFile (* File doesn't exist *)
  | BrokenLink (* Points to wrong file or broken symlink *)

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

(** Helper functions *)

let file_exists path =
  try
    ignore (Unix.stat path);
    true
  with
  | Unix.Unix_error _ -> false
  | _ -> false
;;

let is_symlink path =
  try
    let stat = Unix.lstat path in
    stat.Unix.st_kind = Unix.S_LNK
  with
  | Unix.Unix_error _ -> false
  | _ -> false
;;

let read_symlink_target path =
  try Ok (Unix.readlink path) with
  | Unix.Unix_error (error, _, _) -> Error (Unix.error_message error)
  | e -> Error (Printexc.to_string e)
;;

let resolve_relative_path ~target ~symlink_dir =
  if Filename.is_relative target then Filename.concat symlink_dir target else target
;;

let normalize_path path =
  try Ok (Unix.realpath path) with
  | Unix.Unix_error _ -> Ok path (* Fallback to original path if realpath fails *)
  | e -> Error (Printexc.to_string e)
;;

let read_file_content path =
  try
    let ch = open_in path in
    let content = really_input_string ch (in_channel_length ch) in
    close_in ch;
    Ok content
  with
  | Sys_error msg -> Error msg
  | e -> Error (Printexc.to_string e)
;;

let write_file_content path content =
  try
    let ch = open_out path in
    output_string ch content;
    close_out ch;
    Ok ()
  with
  | Sys_error msg -> Error msg
  | e -> Error (Printexc.to_string e)
;;

let merge_content main_content agent_content =
  let timestamp = string_of_float (Unix.time ()) in
  if String.trim main_content = ""
  then agent_content
  else if String.trim agent_content = ""
  then main_content
  else
    main_content
    ^ "\n\n# Merged content from agent file at "
    ^ timestamp
    ^ "\n\n"
    ^ agent_content
    ^ "\n\n# End merged content\n"
;;

(** Core operations *)

let create_link ~main_guide ~agent_file =
  if not (file_exists main_guide)
  then Error ("Main guide file does not exist: " ^ main_guide)
  else if file_exists agent_file
  then Error ("Agent file already exists: " ^ agent_file)
  else (
    try
      Unix.symlink main_guide agent_file;
      Ok ()
    with
    | Unix.Unix_error (error, _, _) -> Error (Unix.error_message error)
    | e -> Error (Printexc.to_string e))
;;

let check_link ~main_guide ~agent_file =
  if not (file_exists main_guide)
  then MissingFile
  else if not (file_exists agent_file)
  then MissingFile
  else (
    (* Get the directory of the agent file for resolving relative symlinks *)
    let agent_dir = Filename.dirname (Unix.realpath agent_file) in
    (* Normalize main_guide path for comparison *)
    let normalized_main_guide =
      match normalize_path main_guide with
      | Ok path -> path
      | Error _ -> main_guide (* Fallback to original path *)
    in
    if is_symlink agent_file
    then (
      (* It's a symlink, check if it points to the main guide *)
      match read_symlink_target agent_file with
      | Ok target ->
        let resolved_target = resolve_relative_path ~target ~symlink_dir:agent_dir in
        let normalized_target =
          match normalize_path resolved_target with
          | Ok path -> path
          | Error _ -> resolved_target (* Fallback to resolved path *)
        in
        if normalized_target = normalized_main_guide
        then ProperlyLinked { target = normalized_target }
        else BrokenLink
      | Error _ -> BrokenLink)
    else (
      (* It's not a symlink, check if it's a regular file with same content *)
      match read_file_content main_guide, read_file_content agent_file with
      | Ok main_content, Ok agent_content when main_content = agent_content ->
        (* Files have identical content, consider it properly linked *)
        ProperlyLinked { target = normalized_main_guide }
      | Ok _, Ok _ -> BrokenLink
      | Error _, Error _ -> BrokenLink
      | Error _, _ -> BrokenLink
      | _, Error _ -> BrokenLink))
;;

let repair_link ~main_guide ~agent_file =
  if not (file_exists main_guide)
  then Error ("Main guide file does not exist: " ^ main_guide)
  else (
    match check_link ~main_guide ~agent_file with
    | ProperlyLinked _ -> Ok () (* Already properly linked *)
    | MissingFile ->
      (* Agent file doesn't exist, just create the link *)
      create_link ~main_guide ~agent_file
    | NotLinked | BrokenLink ->
      (* Agent file exists but is not a proper link, need to merge content *)
      (match read_file_content main_guide, read_file_content agent_file with
       | Ok main_content, Ok agent_content ->
         let merged_content = merge_content main_content agent_content in
         (match write_file_content main_guide merged_content with
          | Ok () ->
            (* Remove agent file and create link *)
            (try
               Unix.unlink agent_file;
               create_link ~main_guide ~agent_file
             with
             | Unix.Unix_error (error, _, _) -> Error (Unix.error_message error)
             | e -> Error (Printexc.to_string e))
          | Error msg -> Error msg)
       | Error msg, Ok _ -> Error msg
       | Ok _, Error msg -> Error msg
       | Error _, Error _ -> Error "Both files unreadable"))
;;

let remove_link ~agent_file =
  if not (file_exists agent_file)
  then Error ("Agent file does not exist: " ^ agent_file)
  else (
    try
      Unix.unlink agent_file;
      Ok ()
    with
    | Unix.Unix_error (error, _, _) -> Error (Unix.error_message error)
    | e -> Error (Printexc.to_string e))
;;

let get_link_info ~agent_name ~agent_file ~main_guide =
  { agent_name; agent_file; main_guide; status = check_link ~main_guide ~agent_file }
;;

(** Batch operations *)

let check_existing_agent_files ~(config : Config.t) =
  List.fold_left
    (fun acc (agent_name, agent_file) ->
       match check_link ~main_guide:config.main_guide ~agent_file with
       | ProperlyLinked _ -> acc (* Already properly linked, no issue *)
       | MissingFile -> acc (* File doesn't exist, no content to lose *)
       | NotLinked | BrokenLink ->
         (* File exists but is not a proper link, check if it has content *)
         (match read_file_content agent_file with
          | Ok content ->
            if String.trim content <> "" then (agent_name, agent_file) :: acc else acc
          | Error _ -> acc))
    []
    config.agents
;;

let repair_all_links ~(config : Config.t) =
  let result =
    List.fold_left
      (fun acc (agent_name, agent_file) ->
         match repair_link ~main_guide:config.main_guide ~agent_file with
         | Ok () -> { acc with successful = agent_name :: acc.successful }
         | Error msg -> { acc with failed = (agent_name, msg) :: acc.failed })
      { successful = []; failed = [] }
      config.agents
  in
  { successful = List.rev result.successful; failed = List.rev result.failed }
;;

let sync_all_links ~(config : Config.t) =
  let initial_result =
    match write_file_content config.main_guide "" with
    | Ok () -> { successful = []; failed = [] }
    | Error msg -> { successful = []; failed = [ "main_guide", msg ] }
  in
  let final_result =
    List.fold_left
      (fun acc (agent_name, agent_file) ->
         match create_link ~main_guide:config.main_guide ~agent_file with
         | Ok () -> { acc with successful = agent_name :: acc.successful }
         | Error msg -> { acc with failed = (agent_name, msg) :: acc.failed })
      initial_result
      config.agents
  in
  { successful = List.rev final_result.successful; failed = List.rev final_result.failed }
;;
