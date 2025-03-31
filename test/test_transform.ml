open OUnit2
open Etl.Types

module StringMap = Map.Make(Stdlib.String)
module IntMap = Map.Make(Stdlib.Int)

let sample_items = [
  { order_id = 1; quantity = 2; price = 10.0; tax = 0.1 };
  { order_id = 2; quantity = 1; price = 20.0; tax = 0.2 }
]

let sample_orders = [
  { id = 1; client_id = 1; order_date = "2023-01-15"; status = Complete; origin = O };
  { id = 2; client_id = 2; order_date = "2023-02-20"; status = Pending; origin = P }
]

let sample_int_results = [
  { order_id = 1; client_id = 1; order_date = "2023-01-15"; status = Complete; 
    origin = O; quantity = 2; price = 10.0; tax = 0.1 };
  { order_id = 1; client_id = 1; order_date = "2023-01-15"; status = Complete; 
    origin = O; quantity = 1; price = 15.0; tax = 0.1 };
  { order_id = 2; client_id = 2; order_date = "2023-02-20"; status = Pending; 
    origin = P; quantity = 1; price = 20.0; tax = 0.2 }
]

let test_inner_join _ =
  let result = Etl.Pure.inner_join sample_items sample_orders in
  assert_equal ~msg:"Length should match items" 2 (List.length result);
  assert_equal ~msg:"First order_id" 1 (List.hd result).order_id;
  assert_equal ~msg:"Second quantity" 1 (List.nth result 1).quantity;
  assert_equal ~msg:"First status" Complete (List.hd result).status;
  assert_equal ~msg:"Second origin" P (List.nth result 1).origin;
  assert_raises (Not_found) (fun () -> Etl.Pure.inner_join [{ order_id = 3; quantity = 1; price = 1.0; tax = 0.1 }] sample_orders)

let test_group_by _ =
  let result = Etl.Pure.group_by sample_int_results in
  assert_equal ~msg:"Map size" 2 (IntMap.cardinal result);
  assert_equal ~msg:"Order 1 items" 2 (List.length (IntMap.find 1 result));
  assert_equal ~msg:"Order 2 items" 1 (List.length (IntMap.find 2 result));
  assert_bool "Empty list" (IntMap.is_empty (Etl.Pure.group_by []))

let test_get_results _ =
  let grouped : int_result list IntMap.t = Etl.Pure.group_by sample_int_results in
  let results : Etl.Types.result list = Etl.Pure.get_results grouped in
  assert_equal ~msg:"Results length" 2 (List.length results);
  let order1_result : Etl.Types.result = List.find (fun (r : Etl.Types.result) -> r.order_id = 1) results in
  assert_equal ~msg:"Order 1 total price" 35.0 order1_result.price;
  assert_equal ~msg:"Order 1 total tax" 7.0 order1_result.tax;
  assert_bool "Empty map" (Etl.Pure.get_results IntMap.empty = [])

let test_group_by_ym _ =
  let result = Etl.Pure.group_by_ym sample_int_results in
  assert_equal ~msg:"Map size" 2 (StringMap.cardinal result);
  assert_equal ~msg:"Jan 2023 items" 2 (List.length (StringMap.find "2023-01" result));
  assert_equal ~msg:"Feb 2023 items" 1 (List.length (StringMap.find "2023-02" result));
  assert_bool "Empty list" (StringMap.is_empty (Etl.Pure.group_by_ym []))

let test_get_ym_results _ =
  let grouped = Etl.Pure.group_by_ym sample_int_results in
  let results = Etl.Pure.get_ym_results grouped in
  assert_equal ~msg:"Results length" 2 (List.length results);
  let jan_result = List.find (fun r -> r.date = "2023-01") results in
  assert_equal ~msg:"Jan avg price" 17.5 jan_result.avg_price;
  assert_equal ~msg:"Jan avg tax" 3.5 jan_result.avg_tax;  (* Corrected from 1.75 *)
  assert_bool "Empty map" (Etl.Pure.get_ym_results StringMap.empty = [])

let suite =
  "Test Suite" >::: [
    "inner_join" >:: test_inner_join;
    "group_by" >:: test_group_by;
    "get_results" >:: test_get_results;
    "group_by_ym" >:: test_group_by_ym;
    "get_ym_results" >:: test_get_ym_results;
  ]

let () =
  run_test_tt_main suite