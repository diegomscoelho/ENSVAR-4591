#!/bin/sh
grep -Po "(Job|host\(s\)) <.*?>" $(nextflow log boring_joliot | \
    sed 's/$/\/.command.log/g') | \
    grep -Po "<.*>" | \
    sed 's/<//g' | \
    sed 's/>//g' | \
    sed ':a;N;$!ba;s/\nh/\th/g'
