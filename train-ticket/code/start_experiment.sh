#!/bin/bash -i
#set -e

#trap ctrl_c INT
#
#function ctrl_c() {
#        echo "** Trapped CTRL-C"
#	pkill -P $$
#	exit
#}

if [[ $* == *--help* ]]
then
	echo "./start_experiment #iterations idle_time_between_iterations jmx_file_path"
	exit
fi

WATTSUP="$HOME/wattsuppro_logger/WattsupPro.py"
TESTDIR="$HOME/results/"
PROFILER="helpers/measure_performance.py"
CONTAINERS="experiment_configuration_data/containers.csv"
TIMEFORMAT='%3R,%3U,%3S'

#mkdir -p $TESTDIR $TESTDIR/jtl

clist=(75 150 300)

for i in $(seq "$1")
do 
	customers="idle"
	echo "### $i"
	for customers in ${clist[@]}
	do
		CURRENTDIR=$TESTDIR/$i-$customers
		mkdir -p $CURRENTDIR 

		python3 $PROFILER -p unlimitedPower -f $CURRENTDIR/system_pre.json
		python3 $PROFILER -p unlimitedPower -c $CONTAINERS -f $CURRENTDIR/containers_pre.json
		sudo python3 -u $WATTSUP -p /dev/ttyUSB0 -s 1 -o $CURRENTDIR/energy.csv & ENERGY=$! 

		jmeter -Jthreads="$customers" -t $3 -n -l $CURRENTDIR/requests.jtl

		sleep 3 

		python3 $PROFILER -p unlimitedPower -f $CURRENTDIR/system_post.json
		python3 $PROFILER -p unlimitedPower -c $CONTAINERS -f $CURRENTDIR/containers_post.json

		sudo kill -2 $ENERGY #$CONT $PERF

		sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d cf6f2f17dc30 mongo --eval 'db.orders.remove()' ts"
		sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 030d9e0dd407 mongo --eval 'db.contacts.remove()' ts"
		
		if [ $i -lt $1 ]
		then
			sleep $2 
		fi
	done
done
