#!/bin/bash


if [[ `pgrep -c backblur.sh` > 1  ]]; then
    echo "It's already running"
    exit
fi

if [ -z $1 ]; then
    IMGDIR="$HOME/MYWP-NEW"
else
    IMGDIR="$1"
fi
IMGCOUNT="`ls $IMGDIR | wc -l`"
CACHE="$HOME/.cache"
MAINDIR="$CACHE/bgblr"
STATE=0
WP=1

finish(){

feh --bg-scale $MAINDIR/$WP/0
exit 
}

wp_change(){

while :; do

    echo $((($(</dev/shm/wp_num)%$IMGCOUNT)+1)) > /dev/shm/wp_num
    sleep 15;
done

}
blur(){

local blr="$STATE"

while [ $blr -lt "10" ] ;
do
    blr=$[$blr + 1]
    STATE=$[$STATE + 1]
    echo "$blr [+]"
    feh --bg-scale $MAINDIR/$1/$blr
    sleep 0.01
done

}

blur_rev(){

local blr="$STATE"
while [ $blr -gt "0" ] ; 
do
    blr=$[$blr - 1]
    STATE=$[$STATE -1]
    echo $blr
    feh --bg-scale $MAINDIR/$1/$blr
    sleep 0.01
done

}
delete_leftover(){

ls $MAINDIR | while read folder; do 
    if [ $folder -gt $IMGCOUNT ]; then
        rm -rf $MAINDIR/$folder
    fi
done
}
blur_init(){

for i in `seq 10`; do
    
    A=`echo "$((i + 1)) * 2.4"  | bc -l`
    B=`echo "$((i + 1)) * 1.2"  | bc -l`
    convert $IMGDIR/$1 -blur $A,$B $MAINDIR/$2/$i
done

}

if [  ! -d $MAINDIR ] ; then
    mkdir -p $MAINDIR  
fi
i=1
while [ $i -lt $((IMGCOUNT + 1))   ]; do 
    if [ ! -d $MAINDIR/$i ]; then
        mkdir $MAINDIR/$i
    fi
    i=$[$i +1]
done


j=1
for pic in `ls $IMGDIR`; do
    if [[  `md5sum $MAINDIR/$j/0 2>/dev/null | awk '{print $1}'` != `md5sum $IMGDIR/$pic 2>/dev/null | awk '{print $1}'` || `ls $MAINDIR/$j | wc -l` != "11" ]] ;
    then
        blur_init $pic $j
    fi
    j=$((j+1))
done

j=1
for pic in `ls $IMGDIR`; do
    cp $IMGDIR/$pic $MAINDIR/$j/0
    j=$((j+1))
done

delete_leftover 

trap finish EXIT
trap finish SIGHUP
trap finish SIGINT
trap finish SIGKILL
trap finish SIGTERM
if [ ! -s /dev/shm/wp_num ]; then
    echo $WP > /dev/shm/wp_num
fi
wp_change &
while true; do
    WP=$(</dev/shm/wp_num)
    feh --bg-scale $MAINDIR/$WP/$STATE
    CURRWORKSPACE=$(wmctrl -d | grep '*' | cut -d ' ' -f1)
    OPENWINDOWS=$(wmctrl -l | cut -d ' ' -f3 | grep $CURRWORKSPACE | wc -l)
    CURRWALLPAPER=$(tail -n1 ~/.fehbg | cut -d "'" -f2)
    VAR=`basename $CURRWALLPAPER`
    if [[ $OPENWINDOWS > 0 ]] || [[ $(pgrep -cl rofi) > 0 ]] ; then
        if [ `basename $CURRWALLPAPER` != "10" ]; then
            blur $WP
        fi
    else 
        blur_rev $WP
    fi
    sleep 0.5
done
