open Etl.Order
open Etl.Item

let sample_order_csv = 
{|"id","client_id","order_date","status","origin"
"1","112","2024-10-02T03:05:39","Pending","P"|};;

let sample_item_csv = 
{|"order_id","product_id","quantity","price","tax"
"12","224","8","139.42","0.12"|};;

(* Main processing *)
(* 
Printf.printf "teste" *)

let () =
  parse_orders sample_order_csv
  |> List.iter (function
    | Ok order ->
        Printf.printf "%d %d %s %s %s\n"
          order.id
          order.client_id
          order.order_date
          (show_status order.status)
          (show_origin order.origin)
    | Error `Invalid_id ->
        print_endline "Invalid_id"
    | Error `Invalid_date ->
        print_endline "Invalid_date"
    | Error `Unknown_status ->
        print_endline "Unknown_status"
    | Error `Unknown_origin ->
        print_endline "Unknown_origin"
      )

let () =
  parse_items sample_item_csv
  |> List.iter (function
    | Ok item ->
        Printf.printf "%d %d %f %f\n"
          item.order_id
          item.quantity
          item.price
          item.tax
    | Error `Invalid_int ->
        print_endline "Invalid_int"
    | Error `Invalid_float ->
        print_endline "Invalid_float"
      )