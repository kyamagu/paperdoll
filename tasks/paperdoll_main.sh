#!/bin/bash
#
# Main experimental script with Sun Grid Engine (SGE).
# This script can take days.
#
# Use nohup to run this script in the background.
#
# $ nohup ./tasks/paperdoll_main.sh < /dev/null > log/paperdoll_main.log 2>&1 &
#

if [ ! -d log/task103/ ]
then
  mkdir -p log/task103/
fi

# Train prerequisite models from Fashionista dataset.
qsub -sync y tasks/launch.sh task101_train_fashionista_models

# Split the PaperDoll dataset for batch processing.
qsub -sync y tasks/launch.sh task102_split_paperdoll_dataset

# Launch batch offline processes.
qsub -sync y tasks/task103_precompute_paperdoll_dataset.sh

# Collect offline results and index them for use.
qsub -sync y tasks/launch.sh task104_index_paperdoll_dataset

# Fit the PaperDoll pipeline with Fashionista dataset.
qsub -sync y tasks/launch.sh task105_train_paperdoll_models

# Evaluate the results with testing samples.
qsub -sync y tasks/launch.sh task106_evaluate_paperdoll_models
