# WiFi-Perf

Script uses iperf test binary to measure TCP & UDP bandwidth.
Download iperf test binary from https://iperf.fr/iperf-download.php

You can use any version of iperf but iperf2 is preffered, iperf3 reports wrong Loss % most of the time.

Usage: 

run_perf.sh 

[-b bandwidth(default-100)] 
[-T Test name(uu/ud/tu/td/all)(default-all)] 
[-t Time in seconds(default-160)]

