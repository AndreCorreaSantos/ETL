open Etl.Parsers
open Etl.Helpers
open Etl.Pure

let order_csv = read_file "data/order.csv"
let item_csv = read_file "data/order_item.csv"

let orders = unwrap_orders (parse_orders order_csv)

let items = unwrap_items (parse_items item_csv)

(* let () = print_orders orders
let () = print_items items *)

let results = get_results orders items


let () = Printf.printf "%i \n" (List.hd results).order_id

let () = Printf.printf "%f \n" (List.hd results).price




let () = ignore results

