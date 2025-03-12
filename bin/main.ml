open Etl.Parsers
open Etl.Helpers
open Etl.Pure

let order_csv = read_file "data/order.csv"
let item_csv = read_file "data/order_item.csv"

let orders = unwrap_orders (parse_orders order_csv)

let items = parse_items item_csv

(* let () = print_orders orders
let () = print_items items *)

let results = get_results orders

let () = ignore results 
let () = ignore items

