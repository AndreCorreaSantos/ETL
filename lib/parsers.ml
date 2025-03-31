open Types

let ( let* ) = Result.bind
let show_status = function
  | Complete -> "Complete"
  | Pending -> "Pending"
  | Cancelled -> "Cancelled"
let show_origin = function
  | O -> "O"
  | P -> "P"


(** Parses an integer from a string.
    @param raw_int String containing an integer
    @return Parsed integer or an error
*)
let parse_int raw_int =
  raw_int
  |> int_of_string_opt
  |> Option.to_result ~none:`Invalid_int

(** Parses a float from a string.
    @param raw_float String containing a float
    @return Parsed float or an error
*)
let parse_float raw_float =
  raw_float
  |> float_of_string_opt
  |> Option.to_result ~none:`Invalid_float

(** Parses a date from a string.
    @param raw_date String containing a date
    @return Parsed date
*)
let parse_date raw_date = Ok raw_date 

(** Parses a row into an order record.
    @param row CSV row containing order data
    @return Parsed order or an error
*)
let parse_row row =
  let* order_id =
    Csv.Row.find row "order_id" |> parse_int
  in
  let* quantity =
    Csv.Row.find row "quantity" |> parse_int
  in
  let* price = 
    Csv.Row.find row "price" |> parse_float
  in
  let* tax  = 
    Csv.Row.find row "tax" |> parse_float
  in
  Ok { order_id; quantity; price; tax }

(** Parses items from a CSV string.
    @param csv_str CSV data as a string
    @return List of parsed items
*)
let parse_items csv_str =
  csv_str
  |> Csv.of_string ~has_header:true
  |> Csv.Rows.input_all
  |> List.map parse_row

(** Parses an order status from a string.
    @param status_str String representation of the status
    @return Parsed status or an error
*)
let parse_status = function
  | "Complete" -> Ok Complete
  | "Pending" -> Ok Pending
  | "Cancelled" -> Ok Cancelled
  | _ -> Error `Unknown_status

(** Parses an order origin from a string.
    @param origin_str String representation of the origin
    @return Parsed origin or an error
*)
let parse_origin = function
  | "O" -> Ok O
  | "P" -> Ok P
  | _ -> Error `Unknown_origin

(** Parses an ID from a string.
    @param raw_id String containing an ID
    @return Parsed ID or an error
*)
let parse_id raw_id =
  raw_id
  |> int_of_string_opt
  |> Option.to_result ~none:`Invalid_id

(** Parses a row into an order record.
    @param row CSV row containing order data
    @return Parsed order or an error
*)
let parse_row row =
  let* id =
    Csv.Row.find row "id" |> parse_id
  in
  let* client_id =
    Csv.Row.find row "client_id" |> parse_id
  in
  let* order_date = 
    Csv.Row.find row "order_date" |> parse_date
  in
  let* status  = 
    Csv.Row.find row "status" |> parse_status
  in
  let* origin = 
    Csv.Row.find row "origin" |> parse_origin
  in
  Ok { id; client_id; order_date; status; origin }

(** Parses orders from a CSV string.
    @param csv_str CSV data as a string
    @return List of parsed orders
*)
let parse_orders csv_str =
  csv_str
  |> Csv.of_string ~has_header:true
  |> Csv.Rows.input_all
  |> List.map parse_row


(** Filters out errors, returning only successful orders.
    @param order_results List of order results
    @return List of successful orders
*)
let unwrap_orders order_results =
  List.filter_map (function
    | Ok order -> Some order
    | Error _ -> None) 
  order_results

(** Filters out errors, returning only successful items.
    @param item_results List of item results
    @return List of successful items
*)
let unwrap_items item_results = 
  List.filter_map (function
  | Ok item -> Some item
  | Error _ -> None)
  item_results



let filter_orders (user_input : user_input) (orders : order list) : order list =  
  let filter_order (user_input : user_input) (ord : order) = 
    let s_flag = match user_input.status_filter with
      | "" -> true
      | _ -> user_input.status_filter = show_status ord.status
    in
    let o_flag = match user_input.origin_filter with
      | "" -> true
      | _ -> user_input.origin_filter = show_origin ord.origin
    in 
    s_flag && o_flag
  in
  List.filter (fun ord -> filter_order user_input ord) orders


