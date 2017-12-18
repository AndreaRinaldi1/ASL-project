#!/bin/bash

connect="ssh arinaldi@"
vm1="arinaldiforaslvms1.westeurope.cloudapp.azure.com"
vm2="arinaldiforaslvms2.westeurope.cloudapp.azure.com"
vm3="arinaldiforaslvms3.westeurope.cloudapp.azure.com"
vm4="arinaldiforaslvms4.westeurope.cloudapp.azure.com"
vm5="arinaldiforaslvms5.westeurope.cloudapp.azure.com"
vm6="arinaldiforaslvms6.westeurope.cloudapp.azure.com"
vm7="arinaldiforaslvms7.westeurope.cloudapp.azure.com"
vm8="arinaldiforaslvms8.westeurope.cloudapp.azure.com"

port=4569

cmdSet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=1:0"
cmdGet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=0:1"

middleware4="10.0.0.10"
middleware5="10.0.0.11"
server="10.0.0.7"

time=80
time2=7

#Check if there is an argument to the script
if [[ $# > 0 ]]; then
        server="$1"
fi

#Check if there is a 2nd argument to the script
if [[ $# > 1 ]]; then
	time="$2"
fi

#define parameter ranges
clients=(10 25 50 75 90 110 130 150)
threads=(1)
workers=(64)

mkdir Set/
mkdir Set/MW4/
mkdir Set/MW5/

mkdir Set/VM1_1/
mkdir Set/VM1_2/
mkdir Set/VM2_1/
mkdir Set/VM2_2/

${connect}${vm1} mkdir Set/
${connect}${vm2} mkdir Set/

${connect}${vm1} mkdir Set/VM1_1/
${connect}${vm1} mkdir Set/VM1_2/
${connect}${vm2} mkdir Set/VM2_1/
${connect}${vm2} mkdir Set/VM2_2/

${connect}${vm8} mkdir Set/
mkdir Set/dstatServer/

for i in {1..3}
do
	${connect}${vm1} mkdir Set/VM1_1/rep${i}/
	${connect}${vm1} mkdir Set/VM1_2/rep${i}/
	${connect}${vm2} mkdir Set/VM2_1/rep${i}/
	${connect}${vm2} mkdir Set/VM2_2/rep${i}/

	mkdir Set/MW4/rep${i}/
	mkdir Set/MW5/rep${i}/
	mkdir Set/VM1_1/rep${i}/
	mkdir Set/VM1_2/rep${i}/
	mkdir Set/VM2_1/rep${i}/
	mkdir Set/VM2_2/rep${i}/
	
	for wt in "${workers[@]}"; do

		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do

				mkdir Set/MW4/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/
				mkdir Set/MW5/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/

				memtierOutput1="Set/VM1_1/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
		        	memtierOutput2="Set/VM1_2/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
				memtierOutput3="Set/VM2_1/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
		        	memtierOutput4="Set/VM2_2/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"

				cmdMemtierFirst="${cmdSet} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
				cmdMemtierSecond="${cmdSet} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

	                        cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s false -m ${server}:11211"
				cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s false -m ${server}:11211"

				${connect}${vm4} $cmdMWstart4 & 
				${connect}${vm5} $cmdMWstart5 &

				sleep 10

				${connect}${vm8} "dstat --output Set/dstat${c}_${wt}.csv 10 ${time2}" &	
				echo $cmdMemtierFirst

				${connect}${vm1} "$cmdMemtierFirst >> ${memtierOutput1}.log 2>&1" &
				${connect}${vm1} "$cmdMemtierSecond >> ${memtierOutput2}.log 2>&1" &
				${connect}${vm2} "$cmdMemtierFirst >> ${memtierOutput3}.log 2>&1" &
				${connect}${vm2} "$cmdMemtierSecond >> ${memtierOutput4}.log 2>&1"

				sleep 2
				echo "kill MW"

				${connect}${vm4} pkill -n java &
				${connect}${vm5} pkill -n java

				sleep 2	
				echo "copy files"

				scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Set/MW4/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/ 
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Set/MW5/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/
			done
		done

		${connect}${vm4} rm -r results/ 
		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	scp -r arinaldi@${vm1}:/home/arinaldi/Set/VM1_1/rep${i}/. /home/andrea/Set/VM1_1/rep${i}/
	scp -r arinaldi@${vm1}:/home/arinaldi/Set/VM1_2/rep${i}/. /home/andrea/Set/VM1_2/rep${i}/

	scp -r arinaldi@${vm2}:/home/arinaldi/Set/VM2_1/rep${i}/. /home/andrea/Set/VM2_1/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Set/VM2_2/rep${i}/. /home/andrea/Set/VM2_2/rep${i}/

	echo "Done all workers for repetition " ${i}
done
scp -r arinaldi@${vm8}:/home/arinaldi/Set/. /home/andrea/Set/dstatServer/
echo "Done Set"


cmdRepopulate="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate2="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=900 --clients=1 --threads=1 --hide-histogram"



mkdir Get/
mkdir Get/MW4/
mkdir Get/MW5/

mkdir Get/VM1_1/
mkdir Get/VM1_2/
mkdir Get/VM2_1/
mkdir Get/VM2_2/

${connect}${vm1} mkdir Get/
${connect}${vm2} mkdir Get/

${connect}${vm1} mkdir Get/VM1_1/
${connect}${vm1} mkdir Get/VM1_2/
${connect}${vm2} mkdir Get/VM2_1/
${connect}${vm2} mkdir Get/VM2_2/

${connect}${vm8} mkdir Get/
mkdir Get/dstatServer/

${connect}${vm1} "$cmdRepopulate"
${connect}${vm2} "$cmdRepopulate2"
	
for i in {1..3}
do

	${connect}${vm1} mkdir Get/VM1_1/rep${i}/
	${connect}${vm1} mkdir Get/VM1_2/rep${i}/
	${connect}${vm2} mkdir Get/VM2_1/rep${i}/
	${connect}${vm2} mkdir Get/VM2_2/rep${i}/

	mkdir Get/MW4/rep${i}/
	mkdir Get/MW5/rep${i}/
	mkdir Get/VM1_1/rep${i}/
	mkdir Get/VM1_2/rep${i}/
	mkdir Get/VM2_1/rep${i}/
	mkdir Get/VM2_2/rep${i}/
	
	for wt in "${workers[@]}"; do

		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do

				mkdir Get/MW4/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/
				mkdir Get/MW5/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/

				memtierOutput1="Get/VM1_1/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}"
		        	memtierOutput2="Get/VM1_2/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}"
				memtierOutput3="Get/VM2_1/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}"
		        	memtierOutput4="Get/VM2_2/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}"

				cmdMemtierFirst="${cmdGet} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
				cmdMemtierSecond="${cmdGet} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

	                        cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s false -m ${server}:11211"
				cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s false -m ${server}:11211"

				${connect}${vm4} $cmdMWstart4 & 
				${connect}${vm5} $cmdMWstart5 &

				sleep 10
				${connect}${vm8} "dstat --output Get/dstat${c}_${wt}.csv 10 ${time2}" &	
				echo $cmdMemtierFirst

				${connect}${vm1} "$cmdMemtierFirst >> ${memtierOutput1}.log 2>&1" &
				${connect}${vm1} "$cmdMemtierSecond >> ${memtierOutput2}.log 2>&1" &
				${connect}${vm2} "$cmdMemtierFirst >> ${memtierOutput3}.log 2>&1" &
				${connect}${vm2} "$cmdMemtierSecond >> ${memtierOutput4}.log 2>&1"

				sleep 2
				echo "kill MW"

				${connect}${vm4} pkill -n java &
				${connect}${vm5} pkill -n java

				sleep 2	
				echo "copy files"

				scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Get/MW4/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/ 
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Get/MW5/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/
			done
		done

		${connect}${vm4} rm -r results/ 
		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	scp -r arinaldi@${vm1}:/home/arinaldi/Get/VM1_1/rep${i}/. /home/andrea/Get/VM1_1/rep${i}/
	scp -r arinaldi@${vm1}:/home/arinaldi/Get/VM1_2/rep${i}/. /home/andrea/Get/VM1_2/rep${i}/

	scp -r arinaldi@${vm2}:/home/arinaldi/Get/VM2_1/rep${i}/. /home/andrea/Get/VM2_1/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Get/VM2_2/rep${i}/. /home/andrea/Get/VM2_2/rep${i}/

	echo "Done all workers for repetition " ${i}
done
scp -r arinaldi@${vm8}:/home/arinaldi/Get/. /home/andrea/Get/dstatServer/
echo "Done Get"

