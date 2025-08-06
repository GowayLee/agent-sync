(** Tests for Project module *)

open OUnit2
open Agent_sync

let test_is_project_dir _ =
  let temp_dir = Filename.temp_file "test_project_" "" in
  Sys.remove temp_dir;
  Unix.mkdir temp_dir 0o755;
  let config_path = Filename.concat temp_dir ".agent-sync.toml" in
  let oc = open_out config_path in
  output_string oc "[core]\nmain_guide = \"AGENT_GUIDE.md\"\n";
  close_out oc;
  try
    assert_equal ~printer:string_of_bool true (Project.is_project_dir temp_dir);
    assert_equal ~printer:string_of_bool false (Project.is_project_dir "/tmp")
  with
  | e ->
    (try Sys.remove config_path with
     | _ -> ());
    (try Sys.rmdir temp_dir with
     | _ -> ());
    raise e
;;

let suite = "Project tests" >::: [ "is project dir" >:: test_is_project_dir ]
