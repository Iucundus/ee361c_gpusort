#!/bin/bash
#Argument: executable filename to run
#Also produces file $2 which lists the time taken for each array size

echo -n > $2

for x in {100000..1000000..100000} ; do
	echo "Testing $1 for input size $x"
	./generate_array $x test${x}.txt 1000
	echo -n "${x} " >> $2
	(time ./${1} test${x}.txt output${x}.txt) 2>&1 | grep sys >> $2
	./validate test${x}.txt output${x}.txt
	echo
	echo
done
