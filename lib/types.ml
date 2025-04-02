
type status = Complete | Pending | Cancelled

type origin = P | O 

type order = {
  id : int;
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

type ym_result = {
  date : string;
  avg_price : float;
  avg_tax : float;
}

type item = {
  order_id : int;
  quantity: int;
  price: float;
  tax: float;
}

type int_result = {
  order_id : int;
  client_id : int;
  order_date : string;
  status : status; 
  origin : origin;
  quantity: int;
  price : float;
  tax : float;
}

type user_input = {
  origin_filter : string;
  status_filter : string;
}