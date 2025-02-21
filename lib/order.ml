(* Cleaner syntax for Result.bind *)
let ( let* ) = Result.bind

(* Core types *)
type status = Complete | Pending | Cancelled

type origin = P | O 

type order = {
  id : int;
  client_id : int;
  order_date : string;
  status : status; 
  origin : origin;
}

(* String representation of types *)
let show_status = function
  | Complete -> "Complete"
  | Pending -> "Pending"
  | Cancelled -> "Cancelled"

  let show_origin = function
  | O -> "O" (*online vs physical *)
  | P -> "P"

(* Parsing functions returning Results *)
let parse_status = function
  | "Complete" -> Ok Complete
  | "Pending" -> Ok Pending
  | "Cancelled" -> Ok Cancelled
  | _ -> Error `Unknown_status

let parse_origin = function
  | "O" -> Ok O
  | "P" -> Ok P
  | _ -> Error `Unknown_origin

let parse_id raw_id =
  raw_id
  |> int_of_string_opt
  |> Option.to_result ~none:`Invalid_id

let parse_date raw_date = Ok raw_date (*come back for proper date format checking later*)

(* Parse a CSV row into an order record *)
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
  Ok { id; client_id; order_date; status; origin}

(* Parse CSV string into list of order results *)
let parse_orders csv_str =
  csv_str
  |> Csv.of_string ~has_header:true
  |> Csv.Rows.input_all
  |> List.map parse_row