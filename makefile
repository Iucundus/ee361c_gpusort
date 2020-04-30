file_helper.o: file_helper.c
	gcc -c file_helper.c -o file_helper.o

file_helper_cuda.o: file_helper_cuda.cu
	nvcc -c file_helper_cuda.cu -o file_helper_cuda.o
	
validate: validate.c file_helper.h file_helper.o
	gcc -o validate validate.c file_helper.o
	
generate_array: generate_array.c file_helper.h file_helper.o
	gcc -o generate_array generate_array.c file_helper.o
	
mergesort: mergesort.cu file_helper.h file_helper_cuda.o
	nvcc -o mergesort mergesort.cu file_helper_cuda.o
	
quicksort: quicksort.cu file_helper.h file_helper_cuda.o
	nvcc -o quicksort quicksort.cu file_helper_cuda.o
	
radix_sort: radix_sort.cu file_helper.h file_helper_cuda.o
	nvcc -o radix_sort radix_sort.cu file_helper_cuda.o
	
brick_sort: brick_sort.cu file_helper.h file_helper_cuda.o
	nvcc -o brick_sort brick_sort.cu file_helper_cuda.o
	
bitonic_sort: bitonic_sort.cu file_helper.h file_helper_cuda.o
	nvcc -o bitonic_sort bitonic_sort.cu file_helper_cuda.o
	
all: mergesort quicksort radix_sort brick_sort bitonic_sort

test100.txt: generate_array
	./generate_array 100 test100.txt 1000
	
test1000.txt: generate_array
	./generate_array 1000 test1000.txt 1000
	
test10000.txt: generate_array
	./generate_array 10000 test10000.txt 1000

runtest-mergesort: test100.txt test1000.txt test10000.txt mergesort validate
	echo 'Testing mergesort for input size 100'
	./mergesort test100.txt output100.txt
	./validate test100.txt output100.txt
	echo " "
	rm output100.txt
	echo " "
	echo " "
	echo 'Testing mergesort for input size 1000'
	./mergesort test1000.txt output1000.txt
	./validate test1000.txt output1000.txt
	echo " "
	rm output1000.txt
	echo " "
	echo " "
	echo 'Testing mergesort for input size 10000'
	./mergesort test10000.txt output10000.txt
	./validate test10000.txt output10000.txt
	rm output10000.txt
	echo " "
	echo " "
	
runtest-quicksort: test100.txt test1000.txt test10000.txt quicksort validate
	echo 'Testing quicksort for input size 100'
	./quicksort test100.txt output100.txt
	./validate test100.txt output100.txt
	echo " "
	rm output100.txt
	echo " "
	echo " "
	echo 'Testing quicksort for input size 1000'
	./quicksort test1000.txt output1000.txt
	./validate test1000.txt output1000.txt
	echo " "
	rm output1000.txt
	echo " "
	echo " "
	echo 'Testing quicksort for input size 10000'
	./quicksort test10000.txt output10000.txt
	./validate test10000.txt output10000.txt
	echo " "
	rm output10000.txt
	echo " "
	echo " "
	
runtest-radix_sort: test100.txt test1000.txt test10000.txt radix_sort validate
	echo 'Testing radix_sort for input size 100'
	./radix_sort test100.txt output100.txt
	./validate test100.txt output100.txt
	echo " "
	rm output100.txt
	echo " "
	echo " "
	echo 'Testing radix_sort for input size 1000'
	./radix_sort test1000.txt output1000.txt
	./validate test1000.txt output1000.txt
	echo " "
	rm output1000.txt
	echo " "
	echo " "
	echo 'Testing radix_sort for input size 10000'
	./radix_sort test10000.txt output10000.txt
	./validate test10000.txt output10000.txt
	echo " "
	rm output10000.txt
	
runtest-brick_sort: test100.txt test1000.txt test10000.txt brick_sort validate
	echo 'Testing brick_sort for input size 100'
	./brick_sort test100.txt output100.txt
	./validate test100.txt output100.txt
	echo " "
	rm output100.txt
	echo " "
	echo " "
	echo 'Testing brick_sort for input size 1000'
	./brick_sort test1000.txt output1000.txt
	./validate test1000.txt output1000.txt
	echo " "
	rm output1000.txt
	echo " "
	echo " "
	echo 'Testing brick_sort for input size 10000'
	./brick_sort test10000.txt output10000.txt
	./validate test10000.txt output10000.txt
	echo " "
	rm output10000.txt
	echo " "
	echo " "
	
runtest-bitonic_sort: test100.txt test1000.txt test10000.txt bitonic_sort validate
	echo 'Testing bitonic_sort for input size 100'
	./bitonic_sort test100.txt output100.txt
	./validate test100.txt output100.txt
	echo " "
	rm output100.txt
	echo " "
	echo " "
	echo 'Testing bitonic_sort for input size 1000'
	./bitonic_sort test1000.txt output1000.txt
	./validate test1000.txt output1000.txt
	echo " "
	rm output1000.txt
	echo " "
	echo " "
	echo 'Testing bitonic_sort for input size 10000'
	./bitonic_sort test10000.txt output10000.txt
	./validate test10000.txt output10000.txt
	echo " "
	rm output10000.txt
	echo " "
	echo " "
	
runtest-all: runtest-mergesort runtest-quicksort runtest-radix_sort runtest-brick_sort runtest-bitonic_sort
	echo 'Tests complete'
