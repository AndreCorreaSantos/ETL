open Types

module IntMap = Map.Make(Int)

let inner_join (items: item list) (orders: order list) = 
  let get_order (item: item) = 
    let order = List.find (fun order -> order.id = item.order_id) orders in
    { order_id = order.id; client_id = order.client_id; 
    order_date = order.order_date; status = order.status; origin = order.origin;
    quantity = item.quantity; price = item.price; tax = item.tax;  }
  in 
  List.map get_order items 
  

let group_by (intermediate_results: int_result list) =
  let add_to_map key value map =
    match IntMap.find_opt key map with
    | Some lst -> 
        let new_lst = value :: lst in
        IntMap.add key new_lst map
    | None -> 
        let new_lst = [value] in
        IntMap.add key new_lst map
  in
  List.fold_left (fun map x -> add_to_map x.order_id x map) IntMap.empty intermediate_results

 

let get_results (inter_results: int_result list) = 
    
  let order_items = group_by inter_results 
  in
  let result_from_items (order_items: int_result list) =
    let total_price = List.fold_left (fun acc it -> acc +. it.price *. float_of_int it.quantity) 0. order_items in
    let total_tax = List.fold_left (fun acc it -> acc +. it.tax *. total_price) 0. order_items in
    let order_id = (List.hd order_items).order_id in
    { order_id = order_id; price = total_price; tax = total_tax } 
  in
  
 IntMap.fold (fun _ items acc -> result_from_items items :: acc) order_items []




