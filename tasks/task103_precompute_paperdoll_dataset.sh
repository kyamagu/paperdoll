#!/bin/sh
#$-cwd
#$-j y
#$-o log/task103/$JOB_ID_$TASK_ID.log
#$-t 1-1000
#$-tc 40
echo task103_precompute_paperdoll_dataset | \
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/lib/x86_64-linux-gnu/libgcc_s.so.1:/lib/x86_64-linux-gnu/libz.so.1 \
    matlab -nodisplay -singleCompThread
