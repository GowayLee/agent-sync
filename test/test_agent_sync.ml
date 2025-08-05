(** Main test runner that aggregates all test suites *)

open OUnit2

(* Main test suite that combines all test modules *)
let suite = Test_config_load.suite
let () = run_test_tt_main suite

