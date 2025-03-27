open Etl.Parsers
open Etl.Helpers
open Etl.Pure


let order_csv = http_get_string "https://raw.githubusercontent.com/AndreCorreaSantos/ETL/refs/heads/main/data/order.csv"
let item_csv = http_get_string "https://raw.githubusercontent.com/AndreCorreaSantos/ETL/refs/heads/main/data/order_item.csv"

let orders = unwrap_orders (parse_orders order_csv)

let items = unwrap_items (parse_items item_csv)


let inter_result = inner_join items orders

let year_month_orders = group_by_ym inter_result

let grouped_result = group_by inter_result

let year_month_results = get_ym_results year_month_orders

let results = List.rev (get_results grouped_result)




let () = write_file "data/result.csv" results



let () = write_to_sqlite create_table insert_result "data/result.db" results 


let () = write_to_sqlite create_ym_table insert_ym_result "data/ym_result.db" year_month_results 

