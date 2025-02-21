open Etl.Impure

let sample_csv = 
{|"id","client_id","order_date","status","origin"
"1","112","2024-10-02T03:05:39","Pending","P"|};;

(* Main processing *)
(* 
Printf.printf "teste" *)

let () =
  parse_orders sample_csv
  |> List.iter (function
    | Ok order ->
        Printf.printf "%d %d %s %s %s\n"
          order.id
          order.client_id
          order.order_date
          (show_status order.status)
          (show_origin order.origin)
    | Error `Invalid_id ->
        print_endline "Invalid_id"
    | Error `Invalid_date ->
        print_endline "Invalid_date"
    | Error `Unknown_status ->
        print_endline "Unknown_status"
    | Error `Unknown_origin ->
        print_endline "Unknown_origin"
    | _ -> print_endline "Unknown_output"  
      )