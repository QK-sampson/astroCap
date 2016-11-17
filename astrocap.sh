#!/bin/bash

################# Astro script (Ver 1) for created by Sampson #####################################
# Captures a series of astrophotos using gphoto2 with dither function of Lin guider.
# Tested on Nikon D5300, D7200, D600, D800E and D810A
#
# $1: Exposure time in seconds
# $2: Interval in seconds
# $3: Number of frames
# $4: Number of dithers (0 or enter => No dither)
# $5: Time for dithering and settlement in seconds
# $6: iso
# $7: Folder name for the target DSO
# Usage: ./astrocap.sh $1 $2 $3 $4 $5 $6 $7 or interactive mode
# Example: ./astrocap.sh 60 10 6 2 30 400 M42 -> Capture 60s x 6 frames with 2 dither frames using iso 400 and interval 10s. Resting 30s for each dither. Folder "M42" would be created and all the jpg file would be saved under this folder.


# Function
round()
{
echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
};

PreView()
{
sudo gphoto2 --auto-detect
echo ""
echo -e "<*** Capture and download preview @iso25600 ***>"
read -p "Capture Preview? (Default: yes (y/n))" capPre
	[ "$capPre" == "" ] && capPre=y
echo ""
	if [ "$capPre" = "y" ]; then
			echo "*****************************"
			read -p "iso? (Default: 25600) :" setIso
				[ "$setIso" == "" ] && setIso=25600
			read -p "Exposure (Default:10s)? :" setExp
				[ "$setExp" == "" ] && setExp=10
			echo "*****************************"
			echo "Preview Capture Start ..."
			sudo gphoto2 --set-config iso=$setIso --set-config capturetarget=1 --set-config shutterspeed=bulb
			sudo gphoto2 -B $setExp --capture-image-and-download --filename "/home/raspex/astrophoto/preview_%H:%M_%S.jpg" --keep-raw --hook-script /usr/bin/gpic.sh

			sudo gphoto2 --set-config iso=200			#default iso for astrophoto
	else
			exit 0;
	fi
echo ""
};

# Base directory for the photos. Change the path for your system
BASE=/home/raspex/astrophoto			# Change it to the path of your default imaging folder
[ -d "$BASE" ] || { echo "$BASE does not exist!"; exit 1; }
cd /home/raspex/astrophoto				# Change it to the path of your default imaging folder

PreView 								# Comment it to disable preview capture

echo -e "Proceed to capture? (y/n)"
read -p "Default: No " -t 300 pro
[ "$pro" == "" ] && pro=n
if [ "$pro" = "y" ]; then

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

		if [ "${5}" == "" ]; then
				read -p "Dithering settle time (s): " settime;				#$5
				[ "$settime" == "" ] && settime=0
			else
				settime=$5;
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
				sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
				echo -e "Interval: ${intval} seconds" && sleep $intval;
			done
			echo ""
			echo -e "********* COMPLETED  *********"
			exit 0;	
		else
			NuOf_sub_frame=$(echo $(round ${NuOf_frame}/${nodither} 0));
		fi
				
for ((d=1; d<=${nodither}; d++));
		do
				for ((i=NuOf_sub_frame; i>0; i--));
						do echo "***************************************"; 
						echo -e "Frame ${cnt}/${NuOf_frame} start. . .";
						[[ "${cnt}" -ne "${NuOf_frame}" ]]
						((cnt = ${cnt}+1));
						sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
						
						if [[ ${cnt} -eq ${NuOf_frame} ]]; then
						LastFram=$cnt;	
						R_cnt=$cnt;
						echo ""
						echo -e "> The last dithering will start . ."
						/home/raspex/lin_guider_pack/lin_guider/tools/lg_tool.pl dither				# Change it to the location of lg_tool.pl in the system
						echo -e "Settle: ${settime} seconds" && sleep $settime;
						
				else
						[[ "${i}" -ne 1 ]] && echo -e "Interval: ${intval} seconds" && sleep $intval;
				fi

				done

		[[ "${LastFram}" -ne "${NuOf_frame}" ]] && echo "" && echo -e "> The ${d}/${nodither} dithering will start . . ." && /home/raspex/lin_guider_pack/lin_guider/tools/lg_tool.pl dither		# Change it to the location of lg_tool.pl in the system
		[[ "${LastFram}" -ne "${NuOf_frame}" ]] && echo -e "Settle: ${settime} seconds" && sleep $settime;
done

((REST_FRAME = NuOf_frame - NuOf_sub_frame*nodither));

				for ((i=REST_FRAME; i>0; i--));
				do echo "***************************************"; 
					echo -e "Frame ${R_cnt}/${NuOf_frame} start. . .";
					((R_cnt = ${R_cnt}+1));
					sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
					sleep $intval;
					
				done
echo -e ""
echo -e "********* COMPLETED *********"
	fi
	exit 0;
else
	exit 0;
fi

