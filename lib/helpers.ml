open Types


let ( let* ) = Lwt.bind

(** Reads the entire contents of a file into a string.
    @param filename Path to the file to read
    @return String containing the full contents of the file
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
  
  let row_to_csv_line row =
    let quote s = "\"" ^ String.escaped s ^ "\"" in
    String.concat ";" (List.map quote row) ^ "\n"
  in
  
  output_string channel (row_to_csv_line header);
  List.iter (fun row -> output_string channel (row_to_csv_line row)) rows;
  
  close_out channel

(** Performs an HTTP GET request.
    @param url URL to fetch
    @return Lwt promise containing result or error message
*)
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

(** Runs HTTP GET and handles result. Wrapper on the http_get function.
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
  Sqlite3.exec db "DROP TABLE IF EXISTS results" |> ignore;
  Sqlite3.exec db "DROP TABLE IF EXISTS ym_results" |> ignore;
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

(** Parses user input to create filter criteria for origin and status.
    Prompts the user to enter numeric choices for origin and status filters,
    converting them into string representations.
    @return Record containing origin_filter and status_filter strings

*)
let parse_user_input () =
  let () = Printf.printf "Type origin filter: \n 0 -> No filter \n 1 -> Online \n 2 -> Physical \n" in
  let origin_input = int_of_string (read_line ()) in
  let () = Printf.printf "Type status filter: \n 0 -> No filter \n 1 -> Pending \n 2 -> Completed \n" in
  let status_input = int_of_string (read_line ()) in
  let origin_filter = match origin_input with
    | 0 -> ""
    | 1 -> "O"
    | 2 -> "P"
    | _ -> failwith "Invalid origin filter: must be 0, 1, or 2"
  in
  let status_filter = match status_input with
    | 0 -> ""
    | 1 -> "Pending"
    | 2 -> "Complete"
    | _ -> failwith "Invalid status filter: must be 0, 1, or 2"
  in {origin_filter = origin_filter; status_filter = status_filter}


