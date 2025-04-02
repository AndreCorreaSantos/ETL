# ETL - EXTRACT, TRANSFORM, LOAD

## 0. Documentation

Docstring generated documentation for the modules and functions which were developed in this project can be seen at: [Project&#39;s Github Pages](https://andrecorreasantos.github.io/ETL/etl/Etl/).

## 1. Extraction

Extraction is the first step in an etl pipeline, it involves ingesting it from a database or data source. In this project the data can be read from a local file or from a given http url. It must be noted however, that this data must be in a csv format.

## 1.1 User Input

The first step in the program's execution is to prompt the user for the order filters - which are read from the terminal by the function [parse_user_input](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-parse_user_input).

```sh
Type origin filter:
 0 -> No filter
 1 -> Online
 2 -> Physical
```

```sh
Type status filter:
 0 -> No filter
 1 -> Pending
 2 -> Completed
```

The provided filters are stored in a record called [user_input](https://andrecorreasantos.github.io/ETL/etl/Etl/Types/index.html#type-user_input) and then used in a latter step to eliminate orders which don't equal the desired fields.

### 1.2 Get data

The main functions in this step are:

- [http_get_string](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-http_get_string) - Downloads a string from the specified url
- [read_file](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-read_file) - Reads a local csv file from the specified path

### 1.3 Create Records

After the strings containing the data in the csv format are loaded, the next step is to store these strings in the corresponding records. In this case, the two record types are:

**Item Record:**

```ocaml
type item = {
    order_id : int;
    quantity : int;
    price : float;
    tax : float;
}
```

**Order Record:**

```ocaml
type order = {
    id : int;
    client_id : int;
    order_date : string;
    status : status;
    origin : origin;
}
```

The main functions associated with parsing the csv data:

- [parse_items](https://andrecorreasantos.github.io/ETL/etl/Etl/Parsers/index.html#val-parse_items) - Parses a csv string of items into a list of item records
- [parse_orders](https://andrecorreasantos.github.io/ETL/etl/Etl/Parsers/index.html#val-parse_orders) - Parses a csv string of orders into a list of order records

### 1.3 Filter Orders

In possession of a list of item and order records, the list of orders is then filtered using the aforementioned `user_input` and the [filter_orders](https://andrecorreasantos.github.io/ETL/etl/Etl/Parsers/index.html#val-filter_orders) function - which returns a list of order records that satisfy the user_input's filters.

## 2. Transform

Transformation is the portion of the ETL which transforms the ingested data and produces the output which will be stored `"Loaded"` in the target system - which is a database in this case.

### 2.1 Inner Join

Before the transform portion of the ETL, the last step of preparation is to join the order and item lists of records. These tables are inner joined by the function [inner_join](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html#val-inner_join) this operation produces a new type of record called [int_result](https://andrecorreasantos.github.io/ETL/etl/Etl/Types/index.html#type-int_result), it contains the original item information and its corresponding order information:

- `int_result`:

```ocaml
type int_result = {

    order_id : int;
    client_id : int;
    order_date : string;
    status : status;
    origin : origin;
    quantity : int;
    price : float;
    tax : float;

}
```

each int_result object is the result of an item field plus its corresponding order `client_id`, `order_date`, `status`, `origin` fields - if such order exists. If a certain item has no corresponding order it is dropped.

### 2.2 Group items by order_id

These [int_result](https://andrecorreasantos.github.io/ETL/etl/Etl/Types/index.html#type-int_result) records are then groupped by their order_id field with the function [group_by](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html#val-group_by), which results in an [IntMap](https://ocaml.org/docs/maps):

```ocaml
{int: int_result list}
```

### 2.3 Get Results

The order results are then calculated. Each result is a record that contains a `total_price` field that is calculated by summing the price of all of its items, and a `total_tax` field which is the total_tax payed in that order - which is calculated by summing up all of the item prices times their tax rate.
These result fields are obtained with Fold Left operations which end up reversing the final record list, so a List.rev is needed to return them to their original order.
This can all be seen in the code for the [get_results](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html#val-get_results) function.

```ocaml
type result = {

    order_id : int;
    price : float;
    tax : float;

}
```

By the end of this operation we are left with a list of [result](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html#val-get_results) objects.

### 2.4 Group items by year_month

The same aforementioned [int_result](https://andrecorreasantos.github.io/ETL/etl/Etl/Types/index.html#type-int_result) (mentioned in step 2.2) are also groupped by their `year_month` field with the function [group_by_ym](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html#val-group_by_ym), this operation produces a [StringMap](https://ocaml.org/docs/maps):

```ocaml
{string: int_result list}
```

### 2.5 Get year_month Results

The same logic described in 2.3 is applied to the the year_month items in order to obtain [ym_results](https://andrecorreasantos.github.io/ETL/etl/Etl/Types/index.html#type-ym_result) - which contain the same fields as the `results` records but have a `string` identifier called `date`. It must be noted that instead of calculating the total order price and tax as is done in 2.3, this step calculates the average price and average tax for all of the items in orders which are grouped by year-month.

```ocaml
type ym_result = {

    date : string;
    avg_price : float;
    avg_tax : float;

}
```

The function which performs the avg_price and avg_tax calculations for the year_month items is called [get_ym_results](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html#val-get_ym_results).

## 3. Load

In principle, the loading step of an ETL requires loading the processed data into a target system. In this project, the target is an Sqlite3 database.
In this project, there are two lists of records that must be written into the output DB, they are the [results](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html#val-get_results) list and the [ym_results](https://andrecorreasantos.github.io/ETL/etl/Etl/Types/index.html#type-ym_result) list.

### 3.1 Creating the Db file

The .db file is created by the [create_db](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-create_db) function, which creates the file itself and calls two other functions [create_table](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-create_table) and [create_ym_table](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-create_ym_table) in order to create a table to store the normal `results` and the `ym_results`. This function returns a db handle that is used in writing to the created tables.

### 3.3 writing to the tables

The db handle returned by the previous step is then received as an argument by the [write_to_sqlite](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-write_to_sqlite) alongside the `results` and `ym_results` and so `write_to_sqlite` iterates over both lists of results and calls their respective insert functions ([insert_result](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-insert_result) and [insert_ym_result](https://andrecorreasantos.github.io/ETL/etl/Etl/Helpers/index.html#val-insert_ym_result)) to write each iterated record to a table.

Finally, after writing all of the `result` and `ym_result` records, the db is closed and the program execution finishes.

## 4. Building

To build the project and run it yourself, one can download ocaml and opam as such:

- installing opam:

```sh
sudo apt update
sudo apt install -y opam
```

- installing ocaml:

```sh
opam switch create 5.2.0
eval $(opam env)
```

- installing the project's dependencies:

```sh
opam install . --deps-only
```

Building the project:

```sh
dune build
```

Running the project:

```sh
dune exec bin/main.exe
```

## 5. Testing

A pure function always produces the same output for a given input and does not read or modify any external state. This means it is both deterministic and free of side effects.

Unit tests are essential for ensuring that business logic behaves as expected. In this project, OCaml's OUnit2 testing library was used to cover all pure functions. These functions are primarily found in the [Parsers](https://andrecorreasantos.github.io/ETL/etl/Etl/Parsers/index.html) and [Transform](https://andrecorreasantos.github.io/ETL/etl/Etl/Transform/index.html) modules. A few test cases were initially written for selected functions, and Claude was used to generalize them to cover all functions.

To run said tests, one can run:

```sh
dune clean
dune build
dune runtest
```

The written tests can be read in the [test/](https://github.com/AndreCorreaSantos/ETL/tree/main/test) folder.

## 6. Honesty section

- Claude was leveraged in the development of unit tests for the pure functions.
- Grok was used in the writing of the docstrings for a good portion of the functions developed for the project.
- Perplexity was used to search github for code snippets for some "not very documented" ocaml libraries such as Sqlite3 and Cohttp-lwt.
- No autocomplete tools such as github copilot or cursor were used in this project.

## Roadmap

## Project Requirements

- [x] 1 The project must be implemented in OCaml.
- [x] 2 To compute the output, it is necessary to use `map`, `reduce`, and `filter`.
- [x] 3 The code must include functions for reading and writing CSV files. This will result in impure functions.
- [x] 4 Separate impure functions from pure functions in the project files.
- [x] 5 The input must be loaded into a list structure of `Record`.
- [x] 6 The use of `Helper Functions` is mandatory for loading fields into a `Record`.
- [x] 7 A project report must be written, explaining how each step was implemented. This serves as a guide for someone who might want to replicate the project in the future. You must declare whether or not Generative AI was used in this report.

## Optional Requirements

- [x] 1 Read the input data from a static file available on the internet (exposed via HTTP).
- [x] 2 Save the output data in an SQLite database.
- [x] 3 It is possible to process input tables separately, but it is preferable to process the data together using an `inner join` operation. In other words, join the tables before starting the `Transform` step.
- [x] 4 Organize the ETL project using `dune`.
- [x] 5 Document all generated functions using the `docstring` format.
- [x] 6 Produce an additional output that contains the average revenue and taxes paid, grouped by month and year.
- [x] 7 Generate complete test files for the pure functions.
