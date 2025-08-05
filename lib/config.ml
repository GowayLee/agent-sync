(** Configuration module for agent-sync *)

type t =
  { main_guide : string
  ; agents : (string * string) list
  }

type parse_error =
  | File_not_found of string
  | Parse_error of string
  | Missing_core_table
  | Missing_main_guide
  | Missing_agent_table
  | Core_table_not_a_table
  | Agents_table_not_a_table
  | Main_guide_not_a_string
  | Invalid_agent_mapping of string

let default_config =
  { main_guide = "AGENT_GUIDE.md"
  ; agents = [ "claude", "CLAUDE.md"; "crush", "CRUSH.md"; "gemini", "GEMINI.md" ]
  }
;;

let config_file = ".agent-sync.toml"

let parse_agents_table (agents_table : Toml.Types.table)
  : ((string * string) list, parse_error) result
  =
  let open Toml.Types in
  let bindings = Table.bindings agents_table in
  let rec loop acc = function
    | [] -> Ok (List.rev acc)
    | (key, value) :: rest ->
      (match value with
       | TString str -> loop ((Table.Key.to_string key, str) :: acc) rest
       | _ ->
         let key_str = Table.Key.to_string key in
         Error
           (Invalid_agent_mapping (Printf.sprintf "Agent %s has non-string value" key_str)))
  in
  loop [] bindings
;;

let load_data (table : Toml.Types.table) : (t, parse_error) result =
  let open Toml.Min in
  let open Toml.Types in
  let open Table in
  let ( let* ) = Result.bind in
  let* core_table =
    match find_opt (key "core") table with
    | Some (TTable t) -> Ok t
    | Some _ -> Error Core_table_not_a_table
    | None -> Error Missing_core_table
  in
  let* main_guide_str =
    match find_opt (key "main_guide") core_table with
    | Some (TString s) -> Ok s
    | Some _ -> Error Main_guide_not_a_string
    | None -> Error Missing_main_guide
  in
  let* agent_table =
    match find_opt (key "agents") table with
    | Some (TTable t) -> Ok t
    | Some _ -> Error Agents_table_not_a_table
    | None -> Error Missing_agent_table
  in
  let* agents = parse_agents_table agent_table in
  Ok { main_guide = main_guide_str; agents }
;;

let load ?(path = config_file) () : (t, parse_error) result =
  if not (Sys.file_exists path)
  then Error (File_not_found path)
  else
    let open Toml in
    match Parser.from_filename path with
    | `Error (msg, loc) ->
      Error
        (Parse_error
           (Printf.sprintf
              "Parse error: %s at %s:%d:%d"
              msg
              loc.source
              loc.line
              loc.column))
    | `Ok toml_table -> load_data toml_table
;;

type save_error =
  | File_write_error of string * string (* path, system error message *)
  | Encoding_error of string (* if string conversion fails *)

let save ?(path = config_file) (config : t) =
  let open Toml.Min in
  let open Toml.Types in
  let open Toml.Printer in
  try
    let toml_data =
      of_key_values
        [ ( key "core"
          , TTable (of_key_values [ key "main_guide", TString config.main_guide ]) )
        ; ( key "agents"
          , TTable
              (of_key_values
                 (List.map
                    (fun (agent_key, agent_value) -> key agent_key, TString agent_value)
                    config.agents)) )
        ]
    in
    let content = string_of_table toml_data in
    Out_channel.with_open_text path (fun oc -> output_string oc content);
    Ok ()
  with
  | Sys_error msg -> Error (File_write_error (path, msg))
  | exn -> Error (Encoding_error (Printexc.to_string exn))
;;

let create_default () = save default_config

let get_agent_filename config agent_name =
  try Some (List.assoc agent_name config.agents) with
  | Not_found -> None
;;

let list_agents config = List.map fst config.agents

let add_agent config agent_name filename =
  { config with agents = (agent_name, filename) :: config.agents }
;;

let remove_agent config agent_name =
  { config with agents = List.remove_assoc agent_name config.agents }
;;
