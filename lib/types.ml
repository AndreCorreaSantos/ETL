
type status = Complete | Pending | Cancelled

let show_status = function
  | Complete -> "Complete"
  | Pending -> "Pending"
  | Cancelled -> "Cancelled"

type origin = P | O 

let show_origin = function
  | O -> "O"
  | P -> "P"

type order = {
  id : int;
  client_id : int;
  order_date : string;
  status : status; 
  origin : origin;
}

type int_result = {
  order_id : int;
  client_id : int;
  order_date : string;
  status : status; 
  origin : origin;
}

type result = {
  order_id : int;
  price : float;
  tax : float;
}

type item = {
  order_id : int;
  quantity: int;
  price: float;
  tax: float;
}


