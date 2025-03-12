open Types

let print_items items = List.iter (function
  | Ok item ->
      Printf.printf "%d %d %f %f\n"
        item.order_id
        item.quantity
        item.price
        item.tax
  | Error `Invalid_int ->
      print_endline "Invalid_int"
  | Error `Invalid_float ->
      print_endline "Invalid_float"
    ) items

let print_orders orders =  List.iter (function
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
    ) orders


let unwrap_orders order_results =
  List.filter_map (function
    | Ok order -> Some order
    | Error _ -> None) 
  order_results

let read_file filename =
  let channel = open_in filename in
  let content = really_input_string channel (in_channel_length channel) in
  close_in channel;
  content
