open Types

(** Prints items, handling successful and error cases.
    @param items List of items wrapped in result type
*)
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

(** Prints orders, handling successful and error cases.
    @param orders List of orders wrapped in result type
*)
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

(** Reads entire file contents.
    @param filename Path to the file
    @return String containing file contents
*)
let read_file filename =
  let channel = open_in filename in
  let content = really_input_string channel (in_channel_length channel) in
  close_in channel;
  content

(** Writes results to a CSV file.
    @param filename Path to the output CSV file
    @param results List of result records to write
*)
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

(** Performs an HTTP GET request.
    @param url URL to fetch
    @return Lwt promise containing result or error message
*)
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

(** Runs HTTP GET and handles result.
    @param url URL to fetch
    @return String containing response body or exits on failure
*)
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

(** Creates results table in SQLite database.
    @param db SQLite database handle
*)
let create_table (db : Sqlite3.db) = 
  match Sqlite3.exec db "CREATE TABLE IF NOT EXISTS results (order_id INTEGER PRIMARY KEY, price FLOAT, tax FLOAT)" with
  | Sqlite3.Rc.OK -> ()  
  | err ->
    Printf.printf "Failed creating sqlite results db: %s\n" (Sqlite3.Rc.to_string err);
    exit 1

(** Creates year month table in SQLite database.
    @param db SQLite database handle
*)
let create_ym_table (db : Sqlite3.db) = 
  match Sqlite3.exec db "CREATE TABLE IF NOT EXISTS ym_results (date TEXT PRIMARY KEY, avg_price FLOAT, avg_tax FLOAT)" with
  | Sqlite3.Rc.OK -> ()  
  | err ->
    Printf.printf "Failed creating sqlite ym_results db: %s\n" (Sqlite3.Rc.to_string err);
    exit 1

(** Inserts a result into SQLite database.
    @param db SQLite database handle
    @param result Record to insert
*)
let insert_result (db : Sqlite3.db) (result : result) = 
  let statement = Sqlite3.prepare db "INSERT INTO results (order_id, price, tax) VALUES (?, ?, ?)" in
  Sqlite3.bind statement 1 (Sqlite3.Data.INT (Int64.of_int result.order_id)) |> ignore;  
  Sqlite3.bind statement 2 (Sqlite3.Data.FLOAT result.price) |> ignore;
  Sqlite3.bind statement 3 (Sqlite3.Data.FLOAT result.tax) |> ignore;  
  Sqlite3.step statement |> ignore;
  Sqlite3.finalize statement |> ignore;
  ()


(** Inserts a year-month result into SQLite database.
    @param db SQLite database handle
    @param result Year-month record to insert
*)
let insert_ym_result (db : Sqlite3.db) (result : ym_result) = 
  let statement = Sqlite3.prepare db "INSERT INTO ym_results (date, avg_price, avg_tax) VALUES (?, ?, ?)" in
  Sqlite3.bind statement 1 (Sqlite3.Data.TEXT result.date) |> ignore;  
  Sqlite3.bind statement 2 (Sqlite3.Data.FLOAT result.avg_price) |> ignore;
  Sqlite3.bind statement 3 (Sqlite3.Data.FLOAT result.avg_tax) |> ignore;  
  Sqlite3.step statement |> ignore;
  Sqlite3.finalize statement |> ignore;
  ()

(** Creates and initializes a SQLite database with required tables.
    @param filename Path to the SQLite database file
    @return Database handle for further operations
*)
let create_db filename =
  let db = Sqlite3.db_open filename in
  let () = create_table db in
  let () = create_ym_table db in
  db

(** Writes results and year-month results to an SQLite database.
    @param db SQLite database handle
    @param results List of result records to insert
    @param ym_results List of year-month result records to insert
*)
let write_to_sqlite db results ym_results = 
  
  let () = List.iter (fun r -> insert_result db r) results in
  let () = List.iter (fun ym_r -> insert_ym_result db ym_r) ym_results in
  
  Sqlite3.db_close db |> ignore;
  ()


let parse_user_input () =
  let () = Printf.printf "Type origin filter: \n 0 -> No filter \n 1 -> Online \n 2 -> Physical \n" in
  let origin_input = int_of_string (read_line ()) in
  let () = Printf.printf "Type status filter: \n 0 -> No filter \n 1 -> Pending \n 2 -> Completed \n" in
  let status_input = int_of_string (read_line ()) in
  
  (* Validate origin *)
  let origin_filter = match origin_input with
    | 0 -> 0
    | 1 -> 1
    | 2 -> 2
    | _ -> failwith "Invalid origin filter: must be 0, 1, or 2"
  in
  
  (* Validate status *)
  let status_filter = match status_input with
    | 0 -> 0
    | 1 -> 1
    | 2 -> 2
    | _ -> failwith "Invalid status filter: must be 0, 1, or 2"
  in {origin_filter = origin_filter; status_filter = status_filter}


