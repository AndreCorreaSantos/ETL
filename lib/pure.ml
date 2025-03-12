(* 
module StringMap = Map.Make(String) *)

(* dicionario, chave é o id da order, valor é uma lista de itens  *)

(* let inner_join orders items =
  let map = StringMap.empty in
  let rec fill_map lst =
    match lst with
    | [] -> []
    | h :: t -> StringMap.add h.order_id *)

open Types

let get_results orders =
  let parse order = print_endline  (string_of_int order.id) in
  let results = List.map (fun x -> parse x) orders in
  results





