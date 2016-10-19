#!/bin/bash

################# Astro script (beta) for Nikon DSLR created by Sampson #####################################
# Captures a series of astrophotos using gphoto2 with dither function of Lin guider.
# Tested on Nikon D5300 and D600
#
# $1: Exposure time in seconds
# $2: Interval in seconds
# $3: Number of frames
# $4: Number of dithers (Number of frames/Number of dithers = Must be integer), No dither => input = 0
# $5: Time for dithering and settlement in seconds
# $6: iso
# Usage: ./caphoto.sh $1 $2 $3 $4 $5 $6 or interactive mode
# Example: ./caphoto.sh 60 10 6 2 30 400 -> Capture 60s x 6 frames with 2 dither frames using iso 400 and interval 10s. Resting 30s for each dither



#######  Capture Preview  (Uncomment for enable capture preview) #######
#sudo gphoto2 --auto-detect
#echo ""
#echo -e "<*** Capture and download preview @iso25600 ***>"
#read -p "Capture Preview? (Default: yes (y/n))" capPre
#	[ "$capPre" == "" ] && capPre=y
#echo ""
#if [ "$capPre" = "y" ]; then
#echo "*****************************"
#read -p "iso? (Default: 25600) :" setIso
#	[ "$setIso" == "" ] && setIso=25600
#read -p "Exposure (Default:8s)? :" setExp
#	[ "$setExp" == "" ] && setExp=8
#echo "*****************************"
#echo "Preview Capture Start ..."
#sudo gphoto2 --set-config iso=$setIso --set-config capturetarget=1 --set-config shutterspeed=bulb
#sudo gphoto2 -B $setExp --capture-image-and-download --keep-raw --hook-script /usr/bin/gpic.sh
#sudo gphoto2 --set-config iso=200		#default iso for astrophoto
#else
#	exit 0;
#fi
#echo ""
#echo -e "Proceed to capture? (y/n)"
#read -p "Default: No " -t 300 pro
#[ "$pro" == "" ] && pro=n
#if [ "$pro" = "y" ]; then
####################################################################

cd /home/raspex/astrophoto					# Change it to the path of your default imaging folder

###################  Start Capture ################################

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
			echo -e "No. of Frame / No. of Dither must = integer";	
			read -p "No. of Dithering : " nodither;						#$4
		else
			nodither=$4;
		fi

		if [ "${5}" == "" ]; then
			read -p "Dithering settle time (s): " settime;				#$5
		else
			settime=$5;
		fi

		if [ "${6}" == "" ]; then		
			read -p "ISO : " ChangeIso;							#$6
		else
			ChangeIso=$6;
		fi
		echo ""

		echo "-------------------- Summary --------------------"
		echo -e "Exposure Time for Each Frame = ${exptime}s"
		echo -e "Interval = ${intval}s"
		echo -e "No.of Frame = ${NuOf_frame}"
		echo -e "No.of Dithering = ${nodither}"
		echo -e "Time for Dither Settlement = ${settime}s"
		echo -e "ISO = ${ChangeIso}"
		echo "--------------------- End ---------------------"
		echo ""

		read -p "Start capture ? (y/n)" -t 60 stcap
		echo ""
		if [ "$stcap" = "y" ]; then
		 echo "Capture start ..."

		sudo gphoto2 --set-config iso=$ChangeIso
		sleep 1

		cnt=1 ;																# Frame counter
		
		if [[ ${nodither} = 0 ]]; then										# No. of dither = 0
			((NuOf_sub_frame = NuOf_frame));
			for ((d=1; d<=${NuOf_frame}; d++));
				do echo "***************************************";
				echo -e "Frame ${cnt}/${NuOf_frame} start. . ." && ((cnt = ${cnt}+1)) ;
				sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
				echo -e "Interval: ${intval} seconds" && sleep $intval;
			done	
		else
			((NuOf_sub_frame = NuOf_frame/nodither))						# No. of frames between two dithers
		fi

for ((d=1; d<=${nodither}; d++));
		do
				for ((i=NuOf_sub_frame; i>0; i--));
						do echo "***************************************";
						echo -e "Frame ${cnt}/${NuOf_frame} start. . .";
						[[ "${cnt}" -ne "${NuOf_frame}" ]] # && echo -e "Count down for dithering: ${i}";
						((cnt = ${cnt}+1));
						sudo gphoto2 -B $exptime --capture-image-and-download --keep-raw --frames 1;
						
						if [[ ${cnt} -eq ${NuOf_frame} ]]; then
						LastFram=$cnt;
						echo -e "The last dithering will start . ."
						/home/raspex/lin_guider_pack/lin_guider/tools/lg_tool.pl dither			# Change it to the location of lg_tool.pl in the system
						echo -e "Settle for ${settime}s" && sleep $settime;
						
				else
						[[ "${i}" -ne 1 ]] && echo -e "Interval: ${intval} seconds" && sleep $intval;
				fi

				done

		[[ "${LastFram}" -ne "${NuOf_frame}" ]] && echo -e "The ${d}/${nodither} dithering will start . . ." && /home/raspex/lin_guider_pack/lin_guider/tools/lg_tool.pl dither		# Change it to the location of lg_tool.pl in the system
		
		echo -e "Settle for ${settime}s" && sleep $settime;
done

echo -e ""
echo -e "********* MISSION COMPLETED *********"
	fi
	exit 0;
##################################################################################################################################

else
	exit 0;
fi

