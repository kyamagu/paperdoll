#!/bin/bash
#$ -cwd
#$ -j y
#$ -o log/$JOB_NAME.$JOB_ID.log

echo $1 | LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/lib/x86_64-linux-gnu/libgcc_s.so.1:/lib/x86_64-linux-gnu/libz.so.1 matlab -nodisplay -singleCompThread