(lang dune 3.17)
(name etl)
(generate_opam_files true)
(source
 (github AndreCorreaSantos/etl))
(authors "André Corrêa Santos <acorreasantos2002@gmail.com>")
(license LICENSE)
(documentation https://url/to/documentation)
(package
 (name etl)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends 
  ocaml
  dune
  csv
  str
  lwt
  cohttp-lwt-unix)
 (tags
  ("add topics" "to describe" your project)))
; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html