open Etl.Order
open Etl.Item
open Etl.Helpers

let order_csv = read_file "data/order.csv"
let item_csv = read_file "data/order_item.csv"

let orders = parse_orders order_csv

let items = parse_items item_csv

let () = print_orders orders
let () = print_items items