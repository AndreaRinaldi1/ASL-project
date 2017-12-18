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

port=4552

middleware4="10.0.0.10"
middleware5="10.0.0.11"
server6="10.0.0.4"
server7="10.0.0.8"
server8="10.0.0.7"

time=90


cmdRepopulate6="memtier_benchmark-master/memtier_benchmark --server=10.0.0.4 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate7="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate8="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"

cmdRepopulate6Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.4 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=900 --clients=1 --threads=1 --hide-histogram"
cmdRepopulate7Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=900 --clients=1 --threads=1 --hide-histogram"
cmdRepopulate8Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=900 --clients=1 --threads=1 --hide-histogram"

cmdMultiGet="memtier_benchmark-master/memtier_benchmark --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=1000 --port=${port} --data-size=1024"

#Check if there is an argument to the script
if [[ $# > 0 ]]; then
        server="$1"
fi

#Check if there is a 2nd argument to the script
if [[ $# > 1 ]]; then
	time="$2"
fi

#define parameter ranges
clients=(2)
threads=(1)
workers=(64)
keys=(1 3 6 9)

mkdir Baseline5/
mkdir Baseline5/5.1/

${connect}${vm1} mkdir Baseline5/
${connect}${vm1} mkdir Baseline5/5.1/
${connect}${vm2} mkdir Baseline5/
${connect}${vm2} mkdir Baseline5/5.1/
${connect}${vm3} mkdir Baseline5/
${connect}${vm3} mkdir Baseline5/5.1/

mkdir Baseline5/5.1/MW/
mkdir Baseline5/5.1/VM1_1/
mkdir Baseline5/5.1/VM1_2/
mkdir Baseline5/5.1/VM2_1/
mkdir Baseline5/5.1/VM2_2/
mkdir Baseline5/5.1/VM3_1/
mkdir Baseline5/5.1/VM3_2/

${connect}${vm1} mkdir Baseline5/5.1/VM1_1/
${connect}${vm1} mkdir Baseline5/5.1/VM1_2/
${connect}${vm2} mkdir Baseline5/5.1/VM2_1/
${connect}${vm2} mkdir Baseline5/5.1/VM2_2/
${connect}${vm3} mkdir Baseline5/5.1/VM3_1/
${connect}${vm3} mkdir Baseline5/5.1/VM3_2/

${connect}${vm1} $cmdRepopulate6 &
${connect}${vm2} $cmdRepopulate7 &
${connect}${vm3} $cmdRepopulate8

${connect}${vm1} $cmdRepopulate6Prime &
${connect}${vm2} $cmdRepopulate7Prime &
${connect}${vm3} $cmdRepopulate8Prime

for i in {1..3}
do
	${connect}${vm1} mkdir Baseline5/5.1/VM1_1/rep${i}/
	${connect}${vm1} mkdir Baseline5/5.1/VM1_2/rep${i}/
	${connect}${vm2} mkdir Baseline5/5.1/VM2_1/rep${i}/
	${connect}${vm2} mkdir Baseline5/5.1/VM2_2/rep${i}/
	${connect}${vm3} mkdir Baseline5/5.1/VM3_1/rep${i}/
	${connect}${vm3} mkdir Baseline5/5.1/VM3_2/rep${i}/

	mkdir Baseline5/5.1/VM1_1/rep${i}/
	mkdir Baseline5/5.1/VM1_2/rep${i}/

	mkdir Baseline5/5.1/VM2_1/rep${i}/
	mkdir Baseline5/5.1/VM2_2/rep${i}/

	mkdir Baseline5/5.1/VM3_1/rep${i}/
	mkdir Baseline5/5.1/VM3_2/rep${i}/
	
	mkdir Baseline5/5.1/MW/rep${i}/
	mkdir Baseline5/5.1/MW/rep${i}/MW4/		
	mkdir Baseline5/5.1/MW/rep${i}/MW5/

	for wt in "${workers[@]}"; do

		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do
				for k in "${keys[@]}"; do

					mkdir Baseline5/5.1/MW/rep${i}/MW4/output_C${c}_T${th}_W${wt}_K${k}_R${i}/
					mkdir Baseline5/5.1/MW/rep${i}/MW5/output_C${c}_T${th}_W${wt}_K${k}_R${i}/
				
					memtierOutput1="Baseline5/5.1/VM1_1/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
	                        	memtierOutput2="Baseline5/5.1/VM1_2/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
					memtierOutput3="Baseline5/5.1/VM2_1/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
	                        	memtierOutput4="Baseline5/5.1/VM2_2/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
					memtierOutput5="Baseline5/5.1/VM3_1/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
	                        	memtierOutput6="Baseline5/5.1/VM3_2/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"

		                        cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s true -m ${server6}:11211 ${server7}:11211 ${server8}:11211"
					cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s true -m ${server6}:11211 ${server7}:11211 ${server8}:11211"
	
					cmdMemtierFirst="${cmdMultiGet} --ratio=1:${k} --multi-key-get=${k} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
					cmdMemtierSecond="${cmdMultiGet} --ratio=1:${k} --multi-key-get=${k} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

					${connect}${vm4} $cmdMWstart4 & 
					${connect}${vm5} $cmdMWstart5 &
	
					sleep 10	
					echo $cmdMemtierFirst
	
					${connect}${vm1} "$cmdMemtierFirst >> ${memtierOutput1}.log 2>&1" &
					${connect}${vm1} "$cmdMemtierSecond >> ${memtierOutput2}.log 2>&1" &
					${connect}${vm2} "$cmdMemtierFirst >> ${memtierOutput3}.log 2>&1" &
					${connect}${vm2} "$cmdMemtierSecond >> ${memtierOutput4}.log 2>&1" &
					${connect}${vm3} "$cmdMemtierFirst >> ${memtierOutput5}.log 2>&1" &
					${connect}${vm3} "$cmdMemtierSecond >> ${memtierOutput6}.log 2>&1" 

					sleep 4
					echo "kill MW"
		
					${connect}${vm4} pkill -n java &
					${connect}${vm5} pkill -n java

					sleep 3	
					echo "copy files"

					scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Baseline5/5.1/MW/rep${i}/MW4/output_C${c}_T${th}_W${wt}_K${k}_R${i}/ 
					scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Baseline5/5.1/MW/rep${i}/MW5/output_C${c}_T${th}_W${wt}_K${k}_R${i}/
				done
			done

		done

		${connect}${vm4} rm -r results/ 
		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline5/5.1/VM1_1/rep${i}/. /home/andrea/Baseline5/5.1/VM1_1/rep${i}/ 
	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline5/5.1/VM1_2/rep${i}/. /home/andrea/Baseline5/5.1/VM1_2/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline5/5.1/VM2_1/rep${i}/. /home/andrea/Baseline5/5.1/VM2_1/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline5/5.1/VM2_2/rep${i}/. /home/andrea/Baseline5/5.1/VM2_2/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline5/5.1/VM3_1/rep${i}/. /home/andrea/Baseline5/5.1/VM3_1/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline5/5.1/VM3_2/rep${i}/. /home/andrea/Baseline5/5.1/VM3_2/rep${i}/
	echo "Done all workers for repetition " ${i}
done

echo "Done 5.1"



mkdir Baseline5/5.2/

${connect}${vm1} mkdir Baseline5/5.2/
${connect}${vm2} mkdir Baseline5/5.2/
${connect}${vm3} mkdir Baseline5/5.2/

mkdir Baseline5/5.2/MW/
mkdir Baseline5/5.2/VM1_1/
mkdir Baseline5/5.2/VM1_2/
mkdir Baseline5/5.2/VM2_1/
mkdir Baseline5/5.2/VM2_2/
mkdir Baseline5/5.2/VM3_1/
mkdir Baseline5/5.2/VM3_2/

${connect}${vm1} mkdir Baseline5/5.2/VM1_1/
${connect}${vm1} mkdir Baseline5/5.2/VM1_2/
${connect}${vm2} mkdir Baseline5/5.2/VM2_1/
${connect}${vm2} mkdir Baseline5/5.2/VM2_2/
${connect}${vm3} mkdir Baseline5/5.2/VM3_1/
${connect}${vm3} mkdir Baseline5/5.2/VM3_2/

for i in {1..3}
do
	${connect}${vm1} mkdir Baseline5/5.2/VM1_1/rep${i}/
	${connect}${vm1} mkdir Baseline5/5.2/VM1_2/rep${i}/
	${connect}${vm2} mkdir Baseline5/5.2/VM2_1/rep${i}/
	${connect}${vm2} mkdir Baseline5/5.2/VM2_2/rep${i}/
	${connect}${vm3} mkdir Baseline5/5.2/VM3_1/rep${i}/
	${connect}${vm3} mkdir Baseline5/5.2/VM3_2/rep${i}/

	mkdir Baseline5/5.2/VM1_1/rep${i}/
	mkdir Baseline5/5.2/VM1_2/rep${i}/

	mkdir Baseline5/5.2/VM2_1/rep${i}/
	mkdir Baseline5/5.2/VM2_2/rep${i}/

	mkdir Baseline5/5.2/VM3_1/rep${i}/
	mkdir Baseline5/5.2/VM3_2/rep${i}/
	
	mkdir Baseline5/5.2/MW/rep${i}/
	mkdir Baseline5/5.2/MW/rep${i}/MW4/		
	mkdir Baseline5/5.2/MW/rep${i}/MW5/

	for wt in "${workers[@]}"; do

		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do
				for k in "${keys[@]}"; do

					mkdir Baseline5/5.2/MW/rep${i}/MW4/output_C${c}_T${th}_W${wt}_K${k}_R${i}/
					mkdir Baseline5/5.2/MW/rep${i}/MW5/output_C${c}_T${th}_W${wt}_K${k}_R${i}/
				
					memtierOutput1="Baseline5/5.2/VM1_1/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
	                        	memtierOutput2="Baseline5/5.2/VM1_2/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
					memtierOutput3="Baseline5/5.2/VM2_1/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
	                        	memtierOutput4="Baseline5/5.2/VM2_2/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
					memtierOutput5="Baseline5/5.2/VM3_1/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"
	                        	memtierOutput6="Baseline5/5.2/VM3_2/rep${i}/output_C${c}_T${th}_W${wt}_K${k}_R${i}"

		                        cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s false -m ${server6}:11211 ${server7}:11211 ${server8}:11211"
					cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s false -m ${server6}:11211 ${server7}:11211 ${server8}:11211"
	
					cmdMemtierFirst="${cmdMultiGet} --ratio=1:${k} --multi-key-get=${k} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
					cmdMemtierSecond="${cmdMultiGet} --ratio=1:${k} --multi-key-get=${k} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

					${connect}${vm4} $cmdMWstart4 & 
					${connect}${vm5} $cmdMWstart5 &
	
					sleep 10	
					echo $cmdMemtierFirst
	
					${connect}${vm1} "$cmdMemtierFirst >> ${memtierOutput1}.log 2>&1" &
					${connect}${vm1} "$cmdMemtierSecond >> ${memtierOutput2}.log 2>&1" &
					${connect}${vm2} "$cmdMemtierFirst >> ${memtierOutput3}.log 2>&1" &
					${connect}${vm2} "$cmdMemtierSecond >> ${memtierOutput4}.log 2>&1" &
					${connect}${vm3} "$cmdMemtierFirst >> ${memtierOutput5}.log 2>&1" &
					${connect}${vm3} "$cmdMemtierSecond >> ${memtierOutput6}.log 2>&1" 

					sleep 4
					echo "kill MW"
		
					${connect}${vm4} pkill -n java &
					${connect}${vm5} pkill -n java

					sleep 3	
					echo "copy files"

					scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Baseline5/5.2/MW/rep${i}/MW4/output_C${c}_T${th}_W${wt}_K${k}_R${i}/ 
					scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Baseline5/5.2/MW/rep${i}/MW5/output_C${c}_T${th}_W${wt}_K${k}_R${i}/
				done
			done

		done

		${connect}${vm4} rm -r results/ 
		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline5/5.2/VM1_1/rep${i}/. /home/andrea/Baseline5/5.2/VM1_1/rep${i}/ 
	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline5/5.2/VM1_2/rep${i}/. /home/andrea/Baseline5/5.2/VM1_2/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline5/5.2/VM2_1/rep${i}/. /home/andrea/Baseline5/5.2/VM2_1/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline5/5.2/VM2_2/rep${i}/. /home/andrea/Baseline5/5.2/VM2_2/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline5/5.2/VM3_1/rep${i}/. /home/andrea/Baseline5/5.2/VM3_1/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline5/5.2/VM3_2/rep${i}/. /home/andrea/Baseline5/5.2/VM3_2/rep${i}/
	echo "Done all workers for repetition " ${i}
done

echo "Done 5.2"
