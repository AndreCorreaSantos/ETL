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

let unwrap_items item_results = 
  List.filter_map (function
  | Ok item -> Some item
  | Error _ -> None)
  item_results

let read_file filename =
  let channel = open_in filename in
  let content = really_input_string channel (in_channel_length channel) in
  close_in channel;
  content

  let write_file (filename : string) (results : result list) =
    let header = ["order_id"; "price"; "tax"] in
    let result_to_row (result : result) =
      [
        string_of_int result.order_id;
        string_of_float result.price;
        string_of_float result.tax;
      ]
    in
    let rows = List.map result_to_row results in
    
    let channel = open_out filename in
    
    (* format string to csv line *)
    let row_to_csv_line row =
      let quote s = "\"" ^ String.escaped s ^ "\"" in
      String.concat ";" (List.map quote row) ^ "\n"
    in
    
    (* write header and rows *)
    output_string channel (row_to_csv_line header);
    List.iter (fun row -> output_string channel (row_to_csv_line row)) rows;
    
    close_out channel

let ( let* ) = Lwt.bind
let http_get url =
  let* (resp, body) =
    Cohttp_lwt_unix.Client.get (Uri.of_string url)
  in
  let code = resp
             |> Cohttp.Response.status
             |> Cohttp.Code.code_of_status in
  if Cohttp.Code.is_success code
  then
    let* b = Cohttp_lwt.Body.to_string body in
    Lwt.return (Ok b)
  else
    Lwt.return (Error (
      Cohttp.Code.reason_phrase_of_code code
    ))


let http_get_string url =
  Lwt_main.run (
    let* result = http_get url in
    match result with
    | Error str ->
       Printf.printf "%s:fail\n" url;
       Printf.printf "Error: %s\n" str;
       exit 1
    | Ok result ->
       Lwt.return result
  )


let create_table (db : Sqlite3.db) = 
  match Sqlite3.exec db "CREATE TABLE IF NOT EXISTS results (order_id INTEGER PRIMARY KEY, price FLOAT, tax FLOAT)" with
  | Sqlite3.Rc.OK -> ()  
  | err ->
    Printf.printf "Failed creating sqlite results db: %s\n" (Sqlite3.Rc.to_string err);
    exit 1

let insert_result (db : Sqlite3.db) (result : result) = 
  let statement = Sqlite3.prepare db "INSERT INTO results (order_id, price, tax) VALUES (?, ?, ?)" in
  Sqlite3.bind statement 1 (Sqlite3.Data.INT (Int64.of_int result.order_id)) |> ignore;  
  Sqlite3.bind statement 2 (Sqlite3.Data.FLOAT result.price) |> ignore;
  Sqlite3.bind statement 3 (Sqlite3.Data.FLOAT result.tax) |> ignore;  
  Sqlite3.step statement |> ignore;
  Sqlite3.finalize statement |> ignore;
  ()

let write_to_sqlite (filename : string) (results : result list) = 
  let db = Sqlite3.db_open filename in
  let () = create_table db in 
  List.iter (fun result -> insert_result db result) results;
  Sqlite3.db_close db |> ignore;
  ()