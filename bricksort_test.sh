#!/bin/bash

for x in {100000..1000000..100000} ; do
	echo "Testing brick sort for input size $x"
	./generate_array $x test${x}.txt 1000
	time ./brick_sort test${x}.txt output${x}.txt
	./validate test${x}.txt output${x}.txt
	echo
	echo
done
