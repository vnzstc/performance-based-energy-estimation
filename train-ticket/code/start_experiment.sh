#!/bin/bash -i

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

clist=(
	75 150 500 225 450 375 300
	150 75 500 450 225 300 375
	75 500 150 300 375 225 450
	150 75 500 450 300 225 375
	450 300 225 375 500 150 75
	225 375 450 300 150 500 75 
	500 450 225 375 75 150 300 
	150 500 75 225 450 375 300
	500 75 375 450 300 225 150
	75 500 150 225 375 300 450
	75 300 150 225 500 375 450
	150 75 500 300 450 225 375
	75 450 225 500 300 375 150
	375 450 150 225 300 75 500
	300 500 225 150 450 75 375
	150 375 450 500 75 225 300
	500 225 75 450 150 375 300
	300 450 225 150 300 500 75
	500 300 75 375 450 225 150
	75 450 500 375 225 300 150
	75 450 150 375 500 225 300
	300 150 450 75 225 500 375
	75 500 150 375 450 225 300
	150 75 225 500 450 300 375
	225 450 500 375 300 150 75
	150 225 500 75 450 300 375
	375 500 225 75 150 300 450
	150 450 500 225 75 375 300
	225 500 450 75 300 150 375
	375 75 300 450 500 150 225
)

#ten_list=(
#	75 150 500
#	150 75 500
#	75 500 150
#	150 75 500
#	500 150 75
#	150 500 75
#	500 75 150
#	150 500 75
#	500 75 150
#	75 500 150
#)

if [ -d "$TESTDIR" ]; then
	sudo rm -r $TESTDIR
fi

mkdir -p $TESTDIR

i=0
for customers in ${clist[@]}
do
	CURRENTDIR=$TESTDIR/$i-$customers
	mkdir -p $CURRENTDIR 

	# start measuring power and performance
	python3 $PROFILER -p unlimitedPower -f $CURRENTDIR/system_pre.json
	python3 $PROFILER -p unlimitedPower -c $CONTAINERS -f $CURRENTDIR/containers_pre.json
	sudo python3 -u $WATTSUP -p /dev/ttyUSB0 -s 1 -o $CURRENTDIR/energy.csv & ENERGY=$! 

	jmeter -Jthreads="$customers" -t $1 -n -l $CURRENTDIR/requests.jtl

	python3 $PROFILER -p unlimitedPower -f $CURRENTDIR/system_post.json
	python3 $PROFILER -p unlimitedPower -c $CONTAINERS -f $CURRENTDIR/containers_post.json
	sudo kill -2 $ENERGY

	# cleaning the databases of the application
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 0422eb616ad6 mongo --eval 'db.orders.remove()' ts"
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 67ab021dc35a mongo --eval 'db.contacts.remove()' ts"
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d e6b3fb634c5e mongo --eval 'db.foodorder.remove()' ts"
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 9d4a0900c503 mongo --eval 'db.consign_record.remove()' ts"
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 42b27b35187f mongo --eval 'db.assurance.remove()' ts"

	echo "Finished $i-$customers"
	i=$((i+1))
	sleep 60 
done
