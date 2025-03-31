open Etl.Parsers
open Etl.Helpers
open Etl.Transform
let user_input = parse_user_input()
let order_csv = http_get_string "https://raw.githubusercontent.com/AndreCorreaSantos/ETL/refs/heads/main/data/order.csv"

let item_csv = http_get_string "https://raw.githubusercontent.com/AndreCorreaSantos/ETL/refs/heads/main/data/order_item.csv"

let orders = filter_orders user_input (unwrap_orders (parse_orders order_csv))

let items =  unwrap_items (parse_items item_csv)

let inter_result = inner_join items orders

let year_month_orders = group_by_ym inter_result

let grouped_result = group_by inter_result

let year_month_results = get_ym_results year_month_orders

let results = List.rev (get_results grouped_result)

let () = write_file "data/result.csv" results

let db = create_db "data/results.db"

let () = write_to_sqlite db results year_month_results


