open Types


let inner_join items orders = 
  let get_order item = 
    let order = List.find (fun order -> order.id = item.order_id) orders in
    { order_id = order.id; client_id = order.client_id; 
  order_date = order.order_date; status = order.status; origin = order.origin }

  in 
  List.map get_order items 
  


(* let get_results orders items =
  (* filter items for order*)
  let order_items order items = 
    List.filter (fun it -> it.order_id = order.id) items 
  in
  
  (* calculate result record from items *)
  let result_from_items order items_for_order =
    let total_price = List.fold_left (fun acc it -> acc +. it.price *. float_of_int it.quantity) 0. items_for_order in
    let total_tax = List.fold_left (fun acc it -> acc +. it.tax *. total_price) 0. items_for_order in
    { order_id = order.id; price = total_price; tax = total_tax }
  in
  List.map (fun order -> 
    let items_for_order = order_items order items in
    result_from_items order items_for_order
  ) orders
 *)


