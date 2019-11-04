#!/bin/sh
#Contact bachchuwarsuraj@gmail.com for any help or concerns.
UDP_bandwidth=100m
which_test=all
time_=160
USAGE="Usage: `basename $0` [-b bandwidth(default-100)] [-T Test name(uu/ud/tu/td/all)(default-all)] [-t Time in seconds(default-160)]"
while getopts b:T:t: OPT; do
    case "$OPT" in
        b)
            UDP_bandwidth=$OPTARG"m"
            
            ;;
        T)
            which_test=$OPTARG
            
            ;;
        t)
            time_=$OPTARG
            
            ;;
        \?)
            # getopts issues an error message
            echo $USAGE >&2
            exit 1
            ;;
    esac
done
temp0()
{
if [ $UDP_bandwidth ]
then
echo "specified"
else
echo "please specify UDP bandwidth"
echo $USAGE >&2
fi
}
echo "Selected UDP bandwidth is :$UDP_bandwidth "
echo "Executing $which_test tests"
echo "Execution time is: $time_ seconds"

sudo adb root
sleep 3
adb remount
adb push iperf /data/
adb push wl /system/bin/
adb shell chmod 777 /system/bin/wl
adb shell chmod 777 /data/iperf
#fetch Host IP & DeviceIP(wlan0 IP- if 0 then exit saying so)
#check system & device in same domain. fetch Host IP & DeviceIP & check domain.
current_t=`date +%m"-"%d"-"%Y"-"%H"-"%M`
echo $current_t
serverlog=$current_t"_server"
clientlog=$current_t"_client"
whole_log=$current_t"_perf_results"
_host_ip=$(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
#need to check ip address is there or not.
_device_ip=$(adb shell netcfg | grep "wlan0" | awk '{print $3}' | awk -F/ '{print $1}')
echo $_host_ip
echo $_device_ip
echo $(echo $_host_ip|awk -F. '{print $1}')
if [ $(echo $_host_ip|awk -F. '{print $1}') -eq $(echo $_device_ip|awk -F. '{print $1}') ] && [ $(echo $_host_ip|awk -F. '{print $2}') -eq $(echo $_device_ip|awk -F. '{print $2}') ] && [ $(echo $_host_ip|awk -F. '{print $3}') -eq $(echo $_device_ip|awk -F. '{print $3}') ]
then 
echo "Domain is same"
else
echo "Host & Device are in different domain. please keep router wired connected with HOst & keep device wirelessly connected with router"
exit
fi
if [ -f /usr/bin/iperf ]
then
echo "iperf installed"
else
echo "install iperf"
exit
fi

if [ $which_test = "all" ] || [ $which_test = "tu" ]
then
echo "Starting TCP Uplink---------------" >> $whole_log.txt
echo "TCP uplink on server(Host) side" >> ./$serverlog.txt
echo "command: iperf -s ">> ./$serverlog.txt
iperf -s -i 1 | tee ./$serverlog.txt &
sleep 3
echo "\n"
echo "TCP Uplink on Client(Device) side:"  >> ./$clientlog.txt
echo "command: adb shell /data/iperf -c $_host_ip -t $time_ -w 524288 " >> ./$clientlog.txt
adb shell /data/iperf -c $_host_ip -t $time_ -w 524288 -i 1 >> ./$clientlog.txt
sleep 2
#ps | grep iperf
kill -9 $(ps | grep iperf | awk '{print $1}')
#kill -9 $(ps | grep iperf | awk '{print $1}')
sleep 3
cat $serverlog.txt >> $whole_log.txt
echo "----------------" >> $whole_log.txt
cat $clientlog.txt >> $whole_log.txt
echo "#######################################" >> $whole_log.txt
adb shell cat /d/sdhci-tegra.0/error_stats >> $whole_log.txt
adb shell wl rssi >> $whole_log.txt
rm $serverlog.txt
rm $clientlog.txt
#cat $whole_log.txt
echo "+++++++++++++++++++++++++++++++++++TCP Uplink Test Done+++++++++++++++++++++++++++++++++++++++++" >> $whole_log.txt
echo "+++++++++++++++++++++++++++++++++++TCP Uplink Test Done+++++++++++++++++++++++++++++++++++++++++"
fi

if [ $which_test = "all" ] || [ $which_test = "td" ]
then
echo "Starting TCP Downlink---------------" >> $whole_log.txt
echo "Starting TCP Downlink---------------"
adb shell /data/iperf -s -i 1 | tee ./$serverlog.txt &
sleep 3
echo "\n"

iperf -c $_device_ip -t $time_ -w 524288 -i 1 >> ./$clientlog.txt 
sleep 2
#ps | grep iperf
adb shell kill -9 $(adb shell "ps | grep iperf" | awk '{print $2}')
#kill -9 $(ps | grep iperf | awk '{print $1}')
sleep 3
echo "TCP Downlink on server(Device) side"  >> $whole_log.txt
echo "command: adb shell /data/iperf -s  ">> $whole_log.txt
cat $serverlog.txt >> $whole_log.txt
echo "----------------" >> $whole_log.txt
echo "TCP Downlink on Client(Host) side:"  >> $whole_log.txt
echo "command: iperf -c $_device_ip -t $time_ -w 524288 " >> $whole_log.txt
cat $clientlog.txt >> $whole_log.txt
echo "#######################################" >> $whole_log.txt
adb shell cat /d/sdhci-tegra.0/error_stats >> $whole_log.txt
adb shell wl rssi >> $whole_log.txt
rm $serverlog.txt
rm $clientlog.txt
#cat $whole_log.txt
echo "+++++++++++++++++++++++++++++++++++TCP Downlink Test Done+++++++++++++++++++++++++++++++++++++++++" >> $whole_log.txt
echo "+++++++++++++++++++++++++++++++++++TCP Downlink Test Done+++++++++++++++++++++++++++++++++++++++++"
fi

if [ $which_test = "all" ] || [ $which_test = "uu" ]
then
echo "Starting UDP Uplink---------------"
echo "Starting UDP Uplink---------------" >> $whole_log.txt
iperf -s -u -i 1 | tee ./$serverlog.txt &
sleep 3
echo "\n"

adb shell /data/iperf -c $_host_ip -u -t $time_ -b $UDP_bandwidth -i 1 >> ./$clientlog.txt
sleep 2
#ps | grep iperf
kill -9 $(ps | grep iperf | awk '{print $1}')
#kill -9 $(ps | grep iperf | awk '{print $1}')
sleep 3
echo "UDP Uplink on server(Host) side"  >> $whole_log.txt
echo "Command: iperf -s -u  ">> $whole_log.txt

cat $serverlog.txt >> $whole_log.txt
echo "----------------" >> $whole_log.txt
echo "UDP Uplink on Client(Device) side:" >> $whole_log.txt
echo "command: adb shell /data/iperf -c $_host_ip -u -t $time_ -b $UDP_bandwidth " >> $whole_log.txt
cat $clientlog.txt >> $whole_log.txt
echo "#######################################" >> $whole_log.txt
adb shell cat /d/sdhci-tegra.0/error_stats >> $whole_log.txt
adb shell wl rssi >> $whole_log.txt
rm $serverlog.txt
rm $clientlog.txt
#cat $whole_log.txt
echo "+++++++++++++++++++++++++++++++++++UDP Uplink Test Done+++++++++++++++++++++++++++++++++++++++++" >> $whole_log.txt
echo "+++++++++++++++++++++++++++++++++++UDP Uplink Test Done+++++++++++++++++++++++++++++++++++++++++"
fi

if [ $which_test = "all" ] || [ $which_test = "ud" ]
then
echo "Starting UDP Downlink---------------"
echo "Starting UDP Downlink---------------" >> $whole_log.txt

adb shell /data/iperf -s -u -i 1 | tee ./$serverlog.txt &
sleep 3
echo "\n"

iperf -c $_device_ip -u -t $time_ -b $UDP_bandwidth -i 1 >> ./$clientlog.txt
sleep 2
#ps | grep iperf
adb shell kill -9 $(adb shell "ps | grep iperf" | awk '{print $2}')
#kill -9 $(ps | grep iperf | awk '{print $1}')
echo " UDP Downlink on server(Device) side" >> $whole_log.txt
echo "Command: adb shell /data/iperf -s -u ">> $whole_log.txt
cat $serverlog.txt >> $whole_log.txt
echo "----------------" >> $whole_log.txt
echo "UDP Downlink on Client(Host) side:" >> $whole_log.txt
echo "command: iperf -c $_device_ip -u -t $time_ -b $UDP_bandwidth  " >> $whole_log.txt
cat $clientlog.txt >> $whole_log.txt
echo "#######################################" >> $whole_log.txt
adb shell cat /d/sdhci-tegra.0/error_stats >> $whole_log.txt
adb shell wl rssi >> $whole_log.txt
rm $serverlog.txt
rm $clientlog.txt
echo "+++++++++++++++++++++++++++++++++++UDP Downlink Test Done+++++++++++++++++++++++++++++++++++++++++" >> $whole_log.txt
echo "+++++++++++++++++++++++++++++++++++UDP Downlink Test Done+++++++++++++++++++++++++++++++++++++++++"
#cat $whole_log.txt
fi
exit
