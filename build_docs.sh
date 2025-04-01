#!/bin/bash
rm -rf docs/*
dune build
dune build @doc
cp -r _build/default/_doc/_html/* docs/