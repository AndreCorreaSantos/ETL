open OUnit2
open Etl.Parsers
open Etl.Types

let string_of_error = function
  | `Invalid_int -> "Invalid_int"
  | `Invalid_float -> "Invalid_float"
  | `Invalid_id -> "Invalid_id"
  | `Unknown_status -> "Unknown_status"
  | `Unknown_origin -> "Unknown_origin"
  | _ -> "Unknown error"

let sample_csv_items = "order_id,quantity,price,tax\n1,2,10.0,0.1\n2,1,20.0,0.2"

let sample_csv_orders = "id,client_id,order_date,status,origin\n1,100,2023-01-15,Complete,O\n2,200,2023-02-20,Pending,P"

let test_parse_int _ =
  assert_equal (Ok 42) (parse_int "42") ~msg:"Valid integer";
  assert_equal (Error `Invalid_int) (parse_int "abc") ~msg:"Invalid integer";
  assert_equal (Ok (-5)) (parse_int "-5") ~msg:"Negative integer"

let test_parse_float _ =
  assert_equal (Ok 3.14) (parse_float "3.14") ~msg:"Valid float";
  assert_equal (Error `Invalid_float) (parse_float "xyz") ~msg:"Invalid float";
  assert_equal (Ok (-0.5)) (parse_float "-0.5") ~msg:"Negative float"

let test_parse_date _ =
  assert_equal (Ok "2023-01-15") (parse_date "2023-01-15") ~msg:"Valid date";
  assert_equal (Ok "") (parse_date "") ~msg:"Empty date"

let test_parse_status _ =
  assert_equal (Ok Complete) (parse_status "Complete") ~msg:"Complete status";
  assert_equal (Ok Pending) (parse_status "Pending") ~msg:"Pending status";
  assert_equal (Ok Cancelled) (parse_status "Cancelled") ~msg:"Cancelled status";
  assert_equal (Error `Unknown_status) (parse_status "Invalid") ~msg:"Invalid status"

let test_parse_origin _ =
  assert_equal (Ok O) (parse_origin "O") ~msg:"Online origin";
  assert_equal (Ok P) (parse_origin "P") ~msg:"Physical origin";
  assert_equal (Error `Unknown_origin) (parse_origin "X") ~msg:"Invalid origin"

let test_parse_id _ =
  assert_equal (Ok 123) (parse_id "123") ~msg:"Valid ID";
  assert_equal (Error `Invalid_id) (parse_id "xyz") ~msg:"Invalid ID";
  assert_equal (Ok 0) (parse_id "0") ~msg:"Zero ID"

let test_parse_items _ =
  let result = parse_items sample_csv_items in
  assert_equal 2 (List.length result) ~msg:"Number of items";
  
  let first_item = List.nth result 0 in
  (match first_item with
  | Ok item ->
      assert_equal 1 item.order_id ~msg:"First item order_id";
      assert_equal 2 item.quantity ~msg:"First item quantity"
  | Error e -> assert_failure ("Unexpected error in first item: " ^ (string_of_error e)));
  
  let second_item = List.nth result 1 in
  (match second_item with
  | Ok item ->
      assert_equal 2 item.order_id ~msg:"Second item order_id";
      assert_equal 1 item.quantity ~msg:"Second item quantity"
  | Error e -> assert_failure ("Unexpected error in second item: " ^ (string_of_error e)))

let test_parse_orders _ =
  let result = parse_orders sample_csv_orders in
  assert_equal 2 (List.length result) ~msg:"Number of orders";
  
  let first_order = List.nth result 0 in
  (match first_order with
  | Ok order ->
      assert_equal 1 order.id ~msg:"First order id";
      assert_equal 100 order.client_id ~msg:"First order client_id";
      assert_equal Complete order.status ~msg:"First order status"
  | Error e -> assert_failure ("Unexpected error in first order: " ^ (string_of_error e)));
  
  let second_order = List.nth result 1 in
  (match second_order with
  | Ok order ->
      assert_equal 2 order.id ~msg:"Second order id";
      assert_equal 200 order.client_id ~msg:"Second order client_id";
      assert_equal Pending order.status ~msg:"Second order status"
  | Error e -> assert_failure ("Unexpected error in second order: " ^ (string_of_error e)))

let test_unwrap_orders _ =
  let order1 = { id = 1; client_id = 100; order_date = "2023-01-15"; status = Complete; origin = O } in
  let order2 = { id = 2; client_id = 200; order_date = "2023-02-20"; status = Pending; origin = P } in
  let order_results = [
    Ok order1;
    Error `Invalid_id;
    Ok order2;
    Error `Unknown_status
  ] in
  
  let unwrapped = unwrap_orders order_results in
  
  assert_equal 2 (List.length unwrapped) ~msg:"Number of unwrapped orders";
  
  assert_equal order1 (List.nth unwrapped 0) ~msg:"First unwrapped order";
  assert_equal order2 (List.nth unwrapped 1) ~msg:"Second unwrapped order"

let test_unwrap_items _ =
  let item1 = { order_id = 1; quantity = 2; price = 10.0; tax = 0.1 } in
  let item2 = { order_id = 2; quantity = 1; price = 20.0; tax = 0.2 } in
  let item_results = [
    Error `Invalid_float;
    Ok item1;
    Error `Invalid_int;
    Ok item2
  ] in
  
  let unwrapped = unwrap_items item_results in
  
  assert_equal 2 (List.length unwrapped) ~msg:"Number of unwrapped items";
  
  assert_equal item1 (List.nth unwrapped 0) ~msg:"First unwrapped item";
  assert_equal item2 (List.nth unwrapped 1) ~msg:"Second unwrapped item"

let suite =
  "Parsers Test Suite" >::: [
    "parse_int" >:: test_parse_int;
    "parse_float" >:: test_parse_float;
    "parse_date" >:: test_parse_date;
    "parse_status" >:: test_parse_status;
    "parse_origin" >:: test_parse_origin;
    "parse_id" >:: test_parse_id;
    "parse_items" >:: test_parse_items;
    "parse_orders" >:: test_parse_orders;
    "unwrap_orders" >:: test_unwrap_orders;
    "unwrap_items" >:: test_unwrap_items;
  ]

let () =
  run_test_tt_main suite
