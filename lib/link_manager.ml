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

(** Helper functions *)

let file_exists path =
  try
    ignore (Unix.stat path);
    true
  with
  | Unix.Unix_error _ -> false
  | _ -> false
;;

let get_inode path =
  try
    let stat = Unix.stat path in
    Ok stat.Unix.st_ino
  with
  | Unix.Unix_error (error, _, _) -> Error (Unix.error_message error)
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
      Unix.link main_guide agent_file;
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
    match get_inode main_guide, get_inode agent_file with
    | Ok main_inode, Ok agent_inode when main_inode = agent_inode ->
      ProperlyLinked { inode = main_inode }
    | Ok _, Ok _ -> BrokenLink
    | Error _, Error _ -> BrokenLink
    | Error _, _ -> BrokenLink
    | _, Error _ -> BrokenLink)
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
