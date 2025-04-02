open Types
module StringMap = Map.Make(Stdlib.String)
module IntMap = Map.Make(Stdlib.Int)

(** Performs an inner join on items and orders.
    @param items List of items
    @param orders List of orders
    @return List of joined order-item records
*)
let inner_join (items: item list) (orders: order list) = 
  let get_order_info (item: item) = 
    match List.find_opt (fun order -> order.id = item.order_id) orders with
    | Some order -> 
        Some { order_id = order.id; client_id = order.client_id; 
               order_date = order.order_date; status = order.status; 
               origin = order.origin; quantity = item.quantity; 
               price = item.price; tax = item.tax }
    | None -> None
  in 
  List.filter_map get_order_info items


(** Groups a list of intermediate results by order ID.
    @param intermediate_results List of intermediate results
    @return Map grouping results by order ID
*)
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

(** Computes final results from intermediate results.
    @param inter_results List of intermediate results
    @return List of aggregated results
*)
let get_results (order_items: int_result list IntMap.t) = 

  let result_from_items (order_items: int_result list) =
    let total_price = List.fold_left (fun acc it -> acc +. it.price *. float_of_int it.quantity) 0. order_items in
    let total_tax = List.fold_left (fun acc it -> acc +. it.tax *. (it.price *. float_of_int it.quantity)) 0. order_items in
    let order_id = (List.hd order_items).order_id in
    { order_id = order_id; price = total_price; tax = total_tax } 
  in
  
 IntMap.fold (fun _ items acc -> result_from_items items :: acc) order_items []

(** Groups a list of intermediate results by order_date (Year-month).
    @param intermediate_results List of intermediate results
    @return Map grouping results by order ID
*)
let group_by_ym (intermediate_results: int_result list) =
  let add_to_map key value map =
    match StringMap.find_opt key map with
    | Some lst -> 
        let new_lst = value :: lst in
        StringMap.add key new_lst map
    | None -> 
        let new_lst = [value] in
        StringMap.add key new_lst map
  in
  let get_year_month date = 
    String.sub date 0 7
  in
  List.fold_left (fun map x -> add_to_map (get_year_month x.order_date) x map) StringMap.empty intermediate_results


(** Computes final results from intermediate results.
    @param inter_results List of intermediate results
    @return List of aggregated results
*)
let get_ym_results (ym_items: int_result list StringMap.t) = 

  let result_from_items (date : string) (ym_items: int_result list) =
    let len = float_of_int (List.fold_left (fun acc it -> acc + it.quantity) 0 ym_items ) in
    let total_price = List.fold_left (fun acc it -> acc +. it.price *. float_of_int it.quantity) 0. ym_items in
    let total_tax = List.fold_left (fun acc it -> acc +. it.tax  *. (it.price *. float_of_int it.quantity)) 0. ym_items in
    { date = date; avg_price = total_price /. len; avg_tax = total_tax /. len } 
  in
  
 StringMap.fold (fun date items acc -> result_from_items date items :: acc) ym_items []
  