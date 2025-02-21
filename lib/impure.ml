(* Cleaner syntax for Result.bind *)
let ( let* ) = Result.bind

(* Core types *)
type color = Red | Yellow | Blue

type fruit = {
  id : int;
  name : string;
  color : color;
}

(* String representation of colors *)
let show_color = function
  | Red -> "Red"
  | Yellow -> "Yellow"
  | Blue -> "Blue"

(* Parsing functions returning Results *)
let parse_color = function
  | "Red" -> Ok Red
  | "Yellow" -> Ok Yellow
  | "Blue" -> Ok Blue
  | _ -> Error `Unknown_color

let parse_id raw_id =
  raw_id
  |> int_of_string_opt
  |> Option.to_result ~none:`Invalid_id

let parse_name = function
  | "" -> Error `Missing_name
  | n -> Ok n

(* Parse a CSV row into a fruit record *)
let parse_row row =
  let* id =
    Csv.Row.find row "id" |> parse_id
  in
  let* name =
    Csv.Row.find row "name" |> parse_name
  in
  let* color =
    Csv.Row.find row "color" |> parse_color
  in
  Ok { id; name; color }

(* Parse CSV string into list of fruit results *)
let parse_fruits csv_str =
  csv_str
  |> Csv.of_string ~has_header:true
  |> Csv.Rows.input_all
  |> List.map parse_row
