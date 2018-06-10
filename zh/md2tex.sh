#!/bin/bash
#set -v on
if [ -d $1 ]; then
echo $1
cd $1
for file in ./*.md
do
echo $file
#if [ -d $file ]; then
#echo $file
name=`basename $file .md`
echo "base name $name"
pandoc -f markdown -t latex  --listings -o $name.tex $name.md
#fi
done
fi
cd ..
