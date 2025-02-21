open Etl.Impure

let sample_csv =
  {|"id","name","color",
    "1","apple","Red",
    "2","lemon","Yellow",
    "3","berry","Blue",|}

(* Main processing *)
let () =
  parse_fruits sample_csv
  |> List.iter (function
    | Ok fruit ->
        Printf.printf "%d %s %s\n"
          fruit.id
          fruit.name
          (show_color fruit.color)
    | Error `Invalid_id ->
        print_endline "Invalid_id"
    | Error `Unknown_color ->
        print_endline "Unknown_color"
    | Error `Missing_name ->
        print_endline "Missing_name")