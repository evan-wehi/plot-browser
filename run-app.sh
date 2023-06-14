#!/bin/bash

cd "$(dirname "$0")"

nohup julia app.jl --paths ../cll-plots/ --urls cll &

