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



let get_results orders items =
  (* filter items for order*)
  let order_items order items = 
    List.filter (fun it -> it.order_id = order.id) items 
  in
  
  (* result record from items *)
  let result_from_items order items_for_order =
    let total_price = List.fold_left (fun acc it -> acc +. it.price *. float_of_int it.quantity) 0. items_for_order in
    let total_tax = List.fold_left (fun acc it -> acc +. it.tax *. float_of_int it.quantity) 0. items_for_order in
    { order_id = order.id; price = total_price; tax = total_tax }
  in
  List.map (fun order -> 
    let items_for_order = order_items order items in
    result_from_items order items_for_order
  ) orders



