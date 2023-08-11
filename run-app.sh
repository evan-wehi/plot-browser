#!/bin/bash

cd "$(dirname "$0")"

kill `cat app.pid`

nohup julia app.jl --paths ../cll-all-patients/ ../cll-some-patients/ --urls all some  &

echo $! > app.pid

