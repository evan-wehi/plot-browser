#!/bin/bash

cd "$(dirname "$0")"

kill `cat app.pid`

nohup julia app.jl --paths ../cll-all-patients/ ../cll-some-patients/ ../cll-individual-patients --urls all some individual &

echo $! > app.pid

