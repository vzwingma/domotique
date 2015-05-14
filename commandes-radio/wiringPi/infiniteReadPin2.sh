#!/bin/sh


pin=$1

echo "Lecture du pin [$pin]"

up=0;
dw=0;


while [ true ]
do

	a=`gpio read $pin`


	if [ "$a" = "1" ]; then
		up=$(($up + 1))	
		dw=0
	elif [ "$a" = "0" ]; then
		dw=$(($dw + 1))
		up=0
	fi

	if [ $up -ge 3 ]; then
		printf %i 1
		up=0
	elif [ $dw -ge 2 ]; then
		printf %i 0
		dw=0
	fi

#	echo $a : $up / $dw
done
