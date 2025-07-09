#!/usr/bin/env bash

mkdir -p bin/
 
odin build src -collection:engine="src/engine" -collection:user="src" -out:"bin/game" 
