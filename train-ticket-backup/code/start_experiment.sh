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
	75 150 500
	150 75 500
	75 500 150
	150 75 500
	500 150 75
	150 500 75
	500 75 150
	150 500 75
	500 75 150
	75 500 150
	75 150 500
	150 75 500
	75 500 150
	150 75 500
	500 150 75
	150 500 75
	500 75 150
	150 500 75
	500 75 150
	75 500 150
	75 150 500
	150 75 500
	75 500 150
	150 75 500
	500 150 75
	150 500 75
	500 75 150
	150 500 75
	500 75 150
	75 500 150
)

ten_list=(
	75 150 500
	150 75 500
	75 500 150
	150 75 500
	500 150 75
	150 500 75
	500 75 150
	150 500 75
	500 75 150
	75 500 150
)

#clist=(1)

if [ -d "$TESTDIR" ]; then
	sudo rm -r $TESTDIR
fi

mkdir -p $TESTDIR

i=0
for customers in ${clist[@]}
do
	echo $customers

	CURRENTDIR=$TESTDIR/$i-$customers
	mkdir -p $CURRENTDIR 

	python3 $PROFILER -p unlimitedPower -f $CURRENTDIR/system_pre.json
	python3 $PROFILER -p unlimitedPower -c $CONTAINERS -f $CURRENTDIR/containers_pre.json
	sudo python3 -u $WATTSUP -p /dev/ttyUSB0 -s 1 -o $CURRENTDIR/energy.csv & ENERGY=$! 

	jmeter -Jthreads="$customers" -t $1 -n -l $CURRENTDIR/requests.jtl

	python3 $PROFILER -p unlimitedPower -f $CURRENTDIR/system_post.json
	python3 $PROFILER -p unlimitedPower -c $CONTAINERS -f $CURRENTDIR/containers_post.json

	sudo kill -2 $ENERGY

	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d cf6f2f17dc30 mongo --eval 'db.orders.remove()' ts"
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 030d9e0dd407 mongo --eval 'db.contacts.remove()' ts"
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 2ee44c741fef mongo --eval 'db.foodorder.remove()' ts"
	sshpass -p "unlimitedPower" ssh vincenzo@145.108.225.7 "docker exec -d 4da85799face mongo --eval 'db.consign_record.remove()' ts"
	
	sleep 120 

	i=$((i+1))
	echo "Finished $i"
done
