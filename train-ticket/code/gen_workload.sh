#!/bin/bash -i
#set -e

#trap ctrl_c INT
#
#function ctrl_c() {
#        echo "** Trapped CTRL-C"
#	pkill -P $$
#	exit
#}

WATTSUP="$HOME/wattsuppro_logger/WattsupPro.py"
TESTDIR="$HOME/tmp/test"
TIMEFORMAT='%3R,%3U,%3S'

mkdir -p $TESTDIR

clist=(38 50)

for i in $(seq "$1")
do 
	cust="idle"
	echo "### $i"
	for cust in ${clist[@]}
	do
		#echo "#$cust"

		python3 get_stats.py -p unlimitedPower -d 1 -f $TESTDIR/$i-$cust-perf.json & PERF=$!
		python3 get_stats.py -p unlimitedPower -c containers.csv -f $TESTDIR/$i-$cust-cperf.json & CONT=$! 
		sudo python3 -u $WATTSUP -p /dev/ttyUSB0 -s 1 -o $TESTDIR/$i-$cust-energy.csv & ENERGY=$! 

		jmeter -Jthreads="$cust" -n -t $3 

		#sleep 12 

		sudo kill -2 $PERF $ENERGY $CONT
		sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d cf6f2f17dc30 mongo --eval 'db.orders.remove()' ts"
		sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 030d9e0dd407 mongo --eval 'db.contacts.remove()' ts"
		
		if [ $i -lt $1 ]
		then
			sleep $2 
		fi
	done
done
