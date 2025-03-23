open Etl.Parsers
open Etl.Helpers
open Etl.Pure


let order_csv = http_get_string "https://raw.githubusercontent.com/AndreCorreaSantos/ETL/refs/heads/main/data/order.csv"
let item_csv = http_get_string "https://raw.githubusercontent.com/AndreCorreaSantos/ETL/refs/heads/main/data/order_item.csv"

let orders = unwrap_orders (parse_orders order_csv)

let items = unwrap_items (parse_items item_csv)

let inter_result = inner_join items orders

let results = List.rev (get_results inter_result)




let () = write_file "data/result.csv" results

let () = write_to_sqlite "data/result.db" results

