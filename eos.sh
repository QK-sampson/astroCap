#!/bin/bash

# Prepare environment
ABSPATH=`cd ${0%/*} && echo $PWD/${0##*/}`
DATE=`date -d "-6 hours" +"%y%m%d"`


round()
{
echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
};

# Base directory for the photos
BASE=/home/raspex/astrophoto
[ -d "$BASE" ] || { echo "$BASE does not exist!"; exit 1; }
cd /home/raspex/astrophoto

##################################################### Capture ##################################################

		sudo gphoto2 --auto-detect --set-config capturetarget=1 --set-config shutterspeed=bulb 

		echo ""
		echo -e "<*** Please input the session information. ***>"
		if [ "${1}" == "" ]; then
			read -p "Exposure Time (s) : " exptime;					#$1
		else
			exptime=$1;
		fi

		if [ "${2}" == "" ]; then
			read -p "Interval (s) >=15: " intval;					#$2
		else
			intval=$2;
		fi

		if [ "${3}" == "" ]; then
			read -p "No. of frame : " NuOf_frame;					#$3
		else
			NuOf_frame=$3;
		fi

		if [ "${4}" == "" ]; then
			read -p "No. of Dithering : " nodither;						#$4
			[ "$nodither" == "" ] && nodither=0
		else
			nodither=$4;
		fi

#		if  [ "${nodither}" -ne "0" ]; then
			if [ "${5}" == "" ]; then
				read -p "Dithering settle time (s): " settime;				#$5
				[ "$settime" == "" ] && settime=0
			else
				settime=$5;
#			fi
		fi
					
		if [ "${6}" == "" ]; then		
			read -p "ISO : " ChangeIso;							#$6
		else
			ChangeIso=$6;
		fi
		
		if [ "${7}" == "" ]; then		
			read -p "Taget Name : " TagetN;							#$7
		else
			TagetN=$7;
		fi
		
		echo ""
		
		Total_In_Ti=`echo "scale=2;${NuOf_frame}*${exptime}/60" | bc -l`
		T_NuOf_frame=`echo "scale=2;${NuOf_frame}-${nodither}-1" | bc -l`
		TotalTime=`echo "scale=2;${Total_In_Ti} + ${nodither}*${settime}/60 + ${T_NuOf_frame}*${intval}/60" | bc -l`
		[ "$nodither" == "0" ] && TotalTime=`echo "scale=2;${Total_In_Ti} + (${NuOf_frame}-1)*${intval}/60" | bc -l`
		

		echo "-------------------- Summary --------------------"
		echo -e "Total Integrated Exposure Time = ${Total_In_Ti} min"
		echo -e "Estimated Total Time = ${TotalTime} min"
		echo -e "Exposure Time for Each Frame = ${exptime}s"
		echo -e "Interval = ${intval}s"
		echo -e "No.of Frame = ${NuOf_frame}"
		echo -e "No.of Dithering = ${nodither}"
		echo -e "Time for Dither Settlement = ${settime}s"
		echo -e "ISO = ${ChangeIso}"
		echo -e "Taget Name = ${TagetN}"
		echo -e "cap ${exptime} ${intval} ${NuOf_frame} ${nodither} ${settime} ${ChangeIso} ${TagetN}" > /usr/bin/recap
		echo "--------------------- End ---------------------"
		echo ""

		read -p "Start capture ? (y/n)" -t 60 stcap
		echo ""
		if [ "$stcap" = "y" ]; then
		
		 
		 FOLDER="$BASE/$TagetN"
		 [ -d "$FOLDER" ] || mkdir -p "$FOLDER" && echo -e "${FOLDER} was created"
		 cd "$FOLDER" || { echo "$FOLDER does not exits!"; exit 1; }
		  echo ""
		 
		 echo "Capture start ..."

		sudo gphoto2 --set-config iso=$ChangeIso
		sleep 1

		##################################################
		cnt=1 ;											# Frame counter
		
		if [[ ${nodither} = 0 ]]; then
			((NuOf_sub_frame = NuOf_frame));
			for ((d=1; d<=${NuOf_frame}; d++));
			do echo "***************************************";
				echo -e "Frame ${cnt}/${NuOf_frame} start. . ." && ((cnt = ${cnt}+1)) ;
#				sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
				sudo gphoto2 --set-config eosremoterelease=Immediate --wait-event=$exptime\s --capture-image-and-download --set-config eosremoterelease=Off --wait-event-and-download=2s --keep-raw;
				echo -e "Interval: ${intval} seconds" && sleep $intval;
			done
			echo ""
			echo -e "********* MISSION COMPLETED  *********"
			exit 0;			
		else
			NuOf_sub_frame=$(echo $(round ${NuOf_frame}/${nodither} 0));
		fi
		
		
for ((d=1; d<=${nodither}; d++));
		do
				for ((i=NuOf_sub_frame; i>0; i--));
						do echo "***************************************"; 
						echo -e "Frame ${cnt}/${NuOf_frame} start. . .";
						[[ "${cnt}" -ne "${NuOf_frame}" ]] # && echo -e "Count down for dithering: ${i}";
						((cnt = ${cnt}+1));
#						sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
						sudo gphoto2 --set-config eosremoterelease=Immediate --wait-event=$exptime\s --capture-image-and-download --set-config eosremoterelease=Off --wait-event-and-download=2s --keep-raw;
						
						if [[ ${cnt} -eq ${NuOf_frame} ]]; then
						LastFram=$cnt;	
						R_cnt=$cnt;
						echo ""
						echo -e "> The last dithering will start . ."
						/home/raspex/lin_guider_pack/lin_guider/tools/lg_tool.pl dither
						echo -e "Settle: ${settime} seconds" && sleep $settime;
						
				else
						[[ "${i}" -ne 1 ]] && echo -e "Interval: ${intval} seconds" && sleep $intval;
				fi

				done

		[[ "${LastFram}" -ne "${NuOf_frame}" ]] && echo "" && echo -e "> The ${d}/${nodither} dithering will start . . ." && /home/raspex/lin_guider_pack/lin_guider/tools/lg_tool.pl dither		
		[[ "${LastFram}" -ne "${NuOf_frame}" ]] && echo -e "Settle: ${settime} seconds" && sleep $settime;
done

###########################################################################
((REST_FRAME = NuOf_frame - NuOf_sub_frame*nodither));

				for ((i=REST_FRAME; i>0; i--));
				do echo "***************************************"; 
					echo -e "Frame ${R_cnt}/${NuOf_frame} start. . .";
					((R_cnt = ${R_cnt}+1));
#					sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
					sudo gphoto2 --set-config eosremoterelease=Immediate --wait-event=$exptime\s --capture-image-and-download --set-config eosremoterelease=Off --wait-event-and-download=2s --keep-raw;
					sleep $intval;
					
				done
echo -e ""
echo -e "********* MISSION COMPLETED  *********"
	fi
	exit 0;
##################################################################################################################################
