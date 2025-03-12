open Types

let ( let* ) = Result.bind

(* parse orders *)

let parse_int raw_int =
  raw_int
  |> int_of_string_opt
  |> Option.to_result ~none:`Invalid_int

let parse_float raw_float =
  raw_float
  |> float_of_string_opt
  |> Option.to_result ~none:`Invalid_float

let parse_date raw_date = Ok raw_date 

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
  Ok { order_id;quantity;price;tax}

(* Parse items *)
let parse_items csv_str =
  csv_str
  |> Csv.of_string ~has_header:true
  |> Csv.Rows.input_all
  |> List.map parse_row


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

let parse_orders csv_str =
  csv_str
  |> Csv.of_string ~has_header:true
  |> Csv.Rows.input_all
  |> List.map parse_row