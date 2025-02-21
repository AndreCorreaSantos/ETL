(* Cleaner syntax for Result.bind *)
let ( let* ) = Result.bind

(* Core types *)

type item = {
  order_id : int;
  quantity: int;
  price: float;
  tax: float;
}


let parse_int raw_int =
  raw_int
  |> int_of_string_opt
  |> Option.to_result ~none:`Invalid_int

let parse_float raw_float =
  raw_float
  |> float_of_string_opt
  |> Option.to_result ~none:`Invalid_float

let parse_date raw_date = Ok raw_date (*come back for proper date format checking later*)

(* Parse a CSV row into an order record *)
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

(* Parse CSV string into list of order results *)
let parse_items csv_str =
  csv_str
  |> Csv.of_string ~has_header:true
  |> Csv.Rows.input_all
  |> List.map parse_row