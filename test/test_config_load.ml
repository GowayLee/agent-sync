(** Tests for Config.load function *)

open OUnit2
open Agent_sync

let temp_file_with_content content =
  let filename = Filename.temp_file "test_" ".toml" in
  let oc = open_out filename in
  output_string oc content;
  close_out oc;
  filename
;;

let cleanup_test_file filename =
  try Sys.remove filename with
  | _ -> ()
;;

let test_file_not_found _ =
  match Config.load ~path:"nonexistent.toml" () with
  | Error (Config.File_not_found path) ->
    assert_equal ~printer:(fun x -> x) "nonexistent.toml" path
  | _ -> assert_failure "Expected File_not_found error"
;;

let test_parse_error _ =
  let test_file = temp_file_with_content "invalid toml content [" in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error (Config.Parse_error _) -> ()
  | _ -> assert_failure "Expected Parse_error"
;;

let test_missing_core_table _ =
  let test_file = temp_file_with_content "[agents]\nclaude = \"CLAUDE.md\"\n" in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error Config.Missing_core_table -> ()
  | _ -> assert_failure "Expected Missing_core_table error"
;;

let test_missing_main_guide _ =
  let test_file = temp_file_with_content "[core]\n[agents]\nclaude = \"CLAUDE.md\"\n" in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error Config.Missing_main_guide -> ()
  | _ -> assert_failure "Expected Missing_main_guide error"
;;

let test_missing_agent_table _ =
  let test_file = temp_file_with_content "[core]\nmain_guide = \"AGENT_GUIDE.md\"\n" in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error Config.Missing_agent_table -> ()
  | _ -> assert_failure "Expected Missing_agent_table error"
;;

let test_core_table_not_a_table _ =
  let test_file =
    temp_file_with_content "core = \"not_a_table\"\n[agents]\nclaude = \"CLAUDE.md\"\n"
  in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error Config.Core_table_not_a_table -> ()
  | _ -> assert_failure "Expected Core_table_not_a_table error"
;;

let test_agents_table_not_a_table _ =
  let test_file =
    temp_file_with_content
      "agents = \"not_a_table\"\n[core]\nmain_guide = \"AGENT_GUIDE.md\"\n"
  in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error Config.Agents_table_not_a_table -> ()
  | Error Config.Missing_agent_table ->
    assert_failure "Expected Agents_table_not_a_table error But Missing_agent_table error"
  | _ -> assert_failure "Expected Agents_table_not_a_table error"
;;

let test_main_guide_not_a_string _ =
  let test_file =
    temp_file_with_content "[core]\nmain_guide = 42\n[agents]\nclaude = \"CLAUDE.md\"\n"
  in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error Config.Main_guide_not_a_string -> ()
  | _ -> assert_failure "Expected Main_guide_not_a_string error"
;;

let test_invalid_agent_mapping _ =
  let test_file =
    temp_file_with_content
      "[core]\nmain_guide = \"AGENT_GUIDE.md\"\n[agents]\nclaude = 42\n"
  in
  let result = Config.load ~path:test_file () in
  cleanup_test_file test_file;
  match result with
  | Error (Config.Invalid_agent_mapping _) -> ()
  | _ -> assert_failure "Expected Invalid_agent_mapping error"
;;

let test_successful_load _ =
  let test_file =
    temp_file_with_content
      "[core]\n\
       main_guide = \"AGENT_GUIDE.md\"\n\
       [agents]\n\
       claude = \"CLAUDE.md\"\n\
       crush = \"CRUSH.md\"\n"
  in
  match Config.load ~path:test_file () with
  | Ok { main_guide; agents } ->
    cleanup_test_file test_file;
    assert_equal ~printer:(fun x -> x) "AGENT_GUIDE.md" main_guide;
    let agent_names = List.map fst agents in
    assert_equal
      ~printer:(fun x -> String.concat ", " x)
      [ "claude"; "crush" ]
      agent_names
  | _ ->
    cleanup_test_file test_file;
    assert_failure "Expected successful load"
;;

let suite =
  "Config.load tests"
  >::: [ "file not found" >:: test_file_not_found
       ; "parse error" >:: test_parse_error
       ; "missing core table" >:: test_missing_core_table
       ; "missing main guide" >:: test_missing_main_guide
       ; "missing agent table" >:: test_missing_agent_table
       ; "core table not a table" >:: test_core_table_not_a_table
       ; "agents table not a table" >:: test_agents_table_not_a_table
       ; "main guide not a string" >:: test_main_guide_not_a_string
       ; "invalid agent mapping" >:: test_invalid_agent_mapping
       ; "successful load" >:: test_successful_load
       ]
;;
