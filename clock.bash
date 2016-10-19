#!/bin/bash

#######Customization#########
#Time options
time_diff=0 #hours to shift from system time
#display options
clock_radius=25 #in characters
redraw_time=5 #in seconds. how long to wait between redrawing the hands
boarder_thickness=1 #in characters and on average. drawing circles with squares isn't clean
minute_hand_thickness=1 #in characters
hour_hand_thickness=1 #in characters
#color options: red, blue, green, cyan, black, white, gray, default
minute_hand_color="blue" 
hour_hand_color="green"
border_color="white"
background_color="default"
#############################

###Debugging#################
debugging=0 
debug_file="/tmp/log.log"
if [[ $debugging = 0 ]]; then debug_file="/dev/null" ; fi
###############################

##System variable initialization
br=1
accuracy="36000" #3600 arseconds in a degree, better accuracy when dealing with integers only. 
pi="3.1415926535897932384626433"
circumference=`echo "((2 * ($clock_radius + $boarder_thickness)) + ((1/$pi)-1)) / (1/$pi)" | bc -l | cut -f1 -d.`
scaling_factor=`echo "(360*$accuracy)/$circumference" | bc -l | cut -f1 -d.`
mangle=0
hangle=0
################################
function set_pixel() {
#first parameter is x coordinate, second is y, third is color.
	color="\e[49m"
	spx=$(($1+1+$boarder_thickness))
	spy=$(($2+1+$boarder_thickness))
	if [ "$3" = "red" ]; then  color="\e[101m" ; fi
	if [ "$3" = "blue" ]; then  color="\e[44m" ; fi
	if [ "$3" = "green" ]; then  color="\e[42m" ; fi
	if [ "$3" = "cyan" ]; then  color="\e[106m" ; fi
	if [ "$3" = "black" ]; then  color="\e[40m" ; fi
	if [ "$3" = "white" ]; then  color="\e[107m" ; fi
	if [ "$3" = "gray" ]; then  color="\e[100m" ; fi
	if [ "$3" = "default" ]; then  color="\e[49m" ; fi
	echo -ne "${color}"
	printf "\033[${spx};${spy}H "
	echo -ne "\e[49m"
	#echo "$x $y" >> $debug_file
}

function trig(){
	ang=$1
	ra=$2
	co=$3
	th=$4
	x=`printf %2.f $(echo "s(((($ang/$accuracy)-90) * $pi / 180)) * $ra + $clock_radius" | bc -l)`
	y=`printf %2.f $(echo "c(((($ang/$accuracy)-90) * $pi / 180)) * $ra + $clock_radius" | bc -l)`
	#if [[ $ma -gt 45 ]] && [[ $ma -lt 135 ]]; then xt=1 ; else yt=1 ; fi
	for ((k=1;k<=$th;k++)); do
		nx=$(($x - ($k-(($th+1)/2)) ))
		ny=$(($y - ($k-(($th+1)/2)) ))
		set_pixel $x $y $co
		set_pixel $x $ny $co
		set_pixel $nx $y $co
		echo "k:$k " >> $debug_file
	done
	echo "trig:  ang:$ang  ra:$ra  co:$co th:$th  x:$x y:$y nx:$nx ny:$ny" >> $debug_file
}
function draw_border() {
	for ((i=0;i<="$((10*($boarder_thickness + $clock_radius)))";i++)); do  echo ; done
	for ((j=1;j<=$boarder_thickness;j++)); do
		for ((i=1;i<=$((360*$accuracy));i+=$(($scaling_factor)))); do
			#echo $i >>$debug_file
			trig $i $(($clock_radius+$j)) $border_color 1
		done
	done
}

function timeme() {
if [ $1 = "1" ]; then stime=`date +"%s"`; else  echo $((`date +"%s"` - $stime)) >> $debug_file ; fi
}


timeme 1
draw_border
timeme 0
while true; do
	minute=`date +"%M"`
	hour=$((10#`date +"%I"` + $time_diff))
	omangle=$mangle
	ohangle=$hangle
	mangle=`echo "$minute * 6 * $accuracy" | bc -l| cut -f1 -d.`
	hangle=`echo "($hour * 60 * $accuracy + $minute) / 2" | bc -l | cut -f1 -d.`
	echo "hangle:$hangle mangle:$mangle omangle:$omangle ohangle:$ohangle " >> $debug_file
	#echo -e "minute: $minute \n hour: $hour\nmangle: $mangle\nhangle:$hangle" >>$debug_file
	for ((j=1;j<="$(($clock_radius-2))";j++)); do
			trig $omangle $j $background_color $minute_hand_thickness
			trig $mangle $j $minute_hand_color $minute_hand_thickness
	done
	for ((j=1;j<="$(($clock_radius/2))";j++)); do
		trig $ohangle $j $background_color $hour_hand_thickness
		trig $hangle $j $hour_hand_color $hour_hand_thickness
	done
		if [ "$br" -ge "$(($clock_radius-1))" ] || [ "$background_color" = "default" ]; then
			sleep $redraw_time
		else
			stime=`date +"%s"`
			for ((j=$br;j<="$(($clock_radius-1))";j++)); do
				bgscale=`echo "(360*$accuracy)/(((2 * ($j)) * $pi ))" | bc -l | cut -f1 -d.`
				for ((i=0;i<=$((360*$accuracy));i+=$(($bgscale)))); do
					trig $i $j $background_color 1
				done
				etime=$((`date +"%s"` - $stime))
				br=$(($j+1))
				#echo "br: $br    j: $j rad: $(($clock_radius-1))" >> $debug_file
				if [ "$etime" -ge "$redraw_time" ]; then  break ; fi
			done
		fi
done


