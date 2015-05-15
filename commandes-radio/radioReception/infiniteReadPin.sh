#!/bin/sh


pin=$1

echo "Lecture du pin [$pin]" 

while [ true ]
do
   printf %s $a
   a=`gpio read $pin`
done
