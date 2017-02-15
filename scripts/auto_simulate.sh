#!/bin/bash

#General steps:
#	* Replace old decorators and retain PhilippinesHuman.standard and MeaslesPhilippines.standard
#	* Copy decorators to decorators/
#	* Remove 'hello.standard'
#	* Edit scenario xml with the correct sequencer
#	* Run simulation
#	* Verify if simulation is saved in Recorded\ Simulations/
## To automatically refresh project explorer view:  http://stackoverflow.com/questions/4727392/how-to-force-a-refresh-on-the-project-explorer-view

# Variables
STEM_DIR="/home/fassster/stem/"
PROJECT_NAME="DenguePhilippinesGeneric"
SEQUENCER_ISMONTHLY="True"

# Constants
SIM_ARCHIVE="saved_sims/"

WORKSPACE_DIR="${STEM_DIR}workspace/"
SRC_DECORATORS_DIR="all_decorators/"
DEST_DECORATORS_DIR="decorators/"
DISCARD="hello.standard"

SEQUENCERS_DIR="sequencers/"
SCENARIOS_DIR="scenarios/"
SCENARIO="${PROJECT_NAME}.scenario"

RECORDED_SIMS_DIR="Recorded\ Simulations/"

SLASH="/"
ALL="*"
BACK="../"

if [ $SEQUENCER_ISMONTHLY == "True" ]; then
	# Adding sequencers per month
	echo "[Using monthly sequencers...]"
	SEQ_LIST=("(28)February_Sequencer.sequencer" "(29)February_Sequencer.sequencer" "(30)Monthly_Sequencer.sequencer" "(31)Monthly_Sequencer.sequencer")
	MONTH_SEQUENCER=(${SEQ_LIST[3]} ${SEQ_LIST[0]} ${SEQ_LIST[3]} ${SEQ_LIST[2]} ${SEQ_LIST[3]} ${SEQ_LIST[2]} ${SEQ_LIST[3]} ${SEQ_LIST[3]} ${SEQ_LIST[2]} ${SEQ_LIST[3]} ${SEQ_LIST[2]} ${SEQ_LIST[3]})
	STRING_TO_REPLACE_MONTHLY="s/(..)Monthly_Sequencer.sequencer/"
	STRING_TO_REPLACE_FEB="s/(..)February_Sequencer.sequencer/"
else
	#Adding sequencers for two months
	echo "[Using two months sequencers...]"
	SEQ_LIST=("(59)Jan_Feb_Sequencer.sequencer" "(60)Jan_Feb_Sequencer.sequencer" "(61)Two_Months_Sequencer.sequencer" "(62)Two_Months_Sequencer.sequencer")
	MONTH_SEQUENCER=(${SEQ_LIST[0]} ${SEQ_LIST[0]} ${SEQ_LIST[2]} ${SEQ_LIST[2]} ${SEQ_LIST[2]} ${SEQ_LIST[2]} ${SEQ_LIST[3]} ${SEQ_LIST[3]} ${SEQ_LIST[2]} ${SEQ_LIST[2]} ${SEQ_LIST[2]} ${SEQ_LIST[2]}) 
	STRING_TO_REPLACE_MONTHLY="s/(..)Two_Months_Sequencer.sequencer/"
	STRING_TO_REPLACE_FEB="s/(..)Jan_Feb_Sequencer.sequencer/"
fi

cd $WORKSPACE_DIR$PROJECT_NAME/
cd $SRC_DECORATORS_DIR
#Iterationg over the files in the decorators
for f in $ALL; 
do
	# Navigating to the project directory
	cd $WORKSPACE_DIR$PROJECT_NAME/ 

	# Delete old decorators except human and Measles standards
	cd $DEST_DECORATORS_DIR
	rm -rf *
	cp -rf ../params/* . 
	echo "[Deleted old decorators...]"
	# Navigating back to the parent directory tree
	cd $WORKSPACE_DIR$PROJECT_NAME/

	# Delete all past recorded simulations
	eval rm -rf ${RECORDED_SIMS_DIR}*
	
	# Navigating back to the parent directory tree
	cd $WORKSPACE_DIR$PROJECT_NAME/
	
	# Saving decorator directory
	DECORATOR=${f}/ 

	echo "[Working on decorator $f]"

	# Copying the decorators to main STEM decorator directory
	cp $SRC_DECORATORS_DIR$DECORATOR$ALL $DEST_DECORATORS_DIR
	echo "[Copied decorators ${DECORATOR} to the decorator directory...]"	

	# Remove "hello.standard"
	rm $DEST_DECORATORS_DIR/$DISCARD

	# Extraction of index for month sequencer
	IFS="-" read -ra DN_PARTS <<< $f
	IFS="_" read -ra DN_WITH_YEAR <<< ${DN_PARTS[0]}

	MONTH=$((10#${DN_PARTS[1]}))
	YEAR=${DN_WITH_YEAR[1]}	

	# If-else for the february 2012 with 29 days for the sequencer
	if [[ $MONTH -eq 2 && $YEAR -eq 2012 ]]; then
		echo "[Used february 2012 sequencer]"
		SEQUENCER=${SEQ_LIST[1]}
	else
		echo "[Used non-february 2012 sequencer]"
		INDEX=`expr $((10#${DN_PARTS[1]})) - 1` # Subtracting 1 to match array position
		SEQUENCER=${MONTH_SEQUENCER[$INDEX]} 
	fi

	# Find and replacing sequencer inside xml file
	echo "[Using sequencer $SEQUENCER...]"
	
	echo "[Find and replacing scenario xml with sequencer...]"
	STRING_REPLACE=$STRING_TO_REPLACE_MONTHLY${SEQUENCER}/
	sed -i -e $STRING_REPLACE $WORKSPACE_DIR$PROJECT_NAME/$SCENARIOS_DIR$SCENARIO

	STRING_REPLACE=$STRING_TO_REPLACE_FEB${SEQUENCER}/
	sed -i -e $STRING_REPLACE $WORKSPACE_DIR$PROJECT_NAME/$SCENARIOS_DIR$SCENARIO
	

	# Navigating back to the stem directory
	cd $STEM_DIR

	# Headlessly running simulation
	./STEM -headless -nosplash -loadWorkspacePlugins -project $PROJECT_NAME
	cd $WORKSPACE_DIR$PROJECT_NAME/
	eval cd $RECORDED_SIMS_DIR
	
	# Moving decorators
	mv ${PROJECT_NAME:0:4}* $DECORATOR
	mv $DECORATOR$SLASH $BACK$SIM_ARCHIVE 
	
	echo "[Finished one round...]"
done

cd $BACK$SLASH$SIM_ARCHIVE
Rscript statAnalysis.R

