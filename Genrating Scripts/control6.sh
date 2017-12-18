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

port=4910

cmdSet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=1:0"
cmdGet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=0:1"
cmd50="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --port=${port} --ratio=1:1"


cmdRepopulate6="memtier_benchmark-master/memtier_benchmark --server=10.0.0.4 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate7="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate8="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"

cmdRepopulate6Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.4 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=500 --clients=1 --threads=1 --hide-histogram"
cmdRepopulate7Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=500 --clients=1 --threads=1 --hide-histogram"
cmdRepopulate8Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=500 --clients=1 --threads=1 --hide-histogram"


middleware4="10.0.0.10"
middleware5="10.0.0.11"
server6="10.0.0.4"
server7="10.0.0.8"
server8="10.0.0.7"

time=90

#Check if there is an argument to the script
if [[ $# > 0 ]]; then
        server="$1"
fi

#Check if there is a 2nd argument to the script
if [[ $# > 1 ]]; then
	time="$2"
fi

#define parameter ranges
clients=(32)
threads=(1)
workers=(32)



mkdir Baseline6/

${connect}${vm1} mkdir Baseline6/
${connect}${vm2} mkdir Baseline6/
${connect}${vm3} mkdir Baseline6/




for wt in "${workers[@]}"; do
	echo "Esperimento Write con 3 servers, 2 middleware e ${wt} worker threads"
	
	mkdir Baseline6/Write_S3_MW2_W${wt}/

	mkdir Baseline6/Write_S3_MW2_W${wt}/MW4/
	mkdir Baseline6/Write_S3_MW2_W${wt}/MW5/

	mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_1/
	mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_2/
	mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_1/
	mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_2/
	mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_1/
	mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_2/


	${connect}${vm1} mkdir Baseline6/Write_S3_MW2_W${wt}/
	${connect}${vm2} mkdir Baseline6/Write_S3_MW2_W${wt}/
	${connect}${vm3} mkdir Baseline6/Write_S3_MW2_W${wt}/

	${connect}${vm1} mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_1/
	${connect}${vm1} mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_2/
	${connect}${vm2} mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_1/
	${connect}${vm2} mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_2/
	${connect}${vm3} mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_1/
	${connect}${vm3} mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_2/

	for i in {1..1}
	do

		${connect}${vm1} mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_1/rep${i}/
		${connect}${vm1} mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_2/rep${i}/
		${connect}${vm2} mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_1/rep${i}/
		${connect}${vm2} mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_2/rep${i}/
		${connect}${vm3} mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_1/rep${i}/
		${connect}${vm3} mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_2/rep${i}/

		mkdir Baseline6/Write_S3_MW2_W${wt}/MW4/rep${i}/
		mkdir Baseline6/Write_S3_MW2_W${wt}/MW5/rep${i}/

		mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_1/rep${i}/
		mkdir Baseline6/Write_S3_MW2_W${wt}/VM1_2/rep${i}/
		mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_1/rep${i}/
		mkdir Baseline6/Write_S3_MW2_W${wt}/VM2_2/rep${i}/
		mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_1/rep${i}/
		mkdir Baseline6/Write_S3_MW2_W${wt}/VM3_2/rep${i}/
	
		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do

				memtierOutput1="Baseline6/Write_S3_MW2_W${wt}/VM1_1/rep${i}/output"
		        	memtierOutput2="Baseline6/Write_S3_MW2_W${wt}/VM1_2/rep${i}/output"
				memtierOutput3="Baseline6/Write_S3_MW2_W${wt}/VM2_1/rep${i}/output"
		        	memtierOutput4="Baseline6/Write_S3_MW2_W${wt}/VM2_2/rep${i}/output"
				memtierOutput5="Baseline6/Write_S3_MW2_W${wt}/VM3_1/rep${i}/output"
		        	memtierOutput6="Baseline6/Write_S3_MW2_W${wt}/VM3_2/rep${i}/output"

				cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s false -m ${server6}:11211 ${server7}:11211 ${server8}:11211"
				cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s false -m ${server6}:11211 ${server7}:11211 ${server8}:11211"

				cmdMemtierFirst="${cmdSet} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
				cmdMemtierSecond="${cmdSet} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

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
				scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/MW4/rep${i}/
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/MW5/rep${i}/
			done
		done

	
	${connect}${vm4} rm -r results/ 
	${connect}${vm5} rm -r results/ 

	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline6/Write_S3_MW2_W${wt}/VM1_1/rep${i}/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/VM1_1/rep${i}/
	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline6/Write_S3_MW2_W${wt}/VM1_2/rep${i}/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/VM1_2/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline6/Write_S3_MW2_W${wt}/VM2_1/rep${i}/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/VM2_1/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline6/Write_S3_MW2_W${wt}/VM2_2/rep${i}/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/VM2_2/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline6/Write_S3_MW2_W${wt}/VM3_1/rep${i}/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/VM3_1/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline6/Write_S3_MW2_W${wt}/VM3_2/rep${i}/. /home/andrea/Baseline6/Write_S3_MW2_W${wt}/VM3_2/rep${i}/
	echo "Done repetition " ${i}
	done
done

workers=(32)

for wt in "${workers[@]}"; do
	echo "Esperimento 50 con 3 servers, 2 middleware e ${wt} worker threads"
	
	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/

	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/MW4/
	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/MW5/

	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_1/
	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_2/
	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_1/
	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_2/
	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_1/
	mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_2/


	${connect}${vm1} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/
	${connect}${vm2} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/
	${connect}${vm3} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/

	${connect}${vm1} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_1/
	${connect}${vm1} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_2/
	${connect}${vm2} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_1/
	${connect}${vm2} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_2/
	${connect}${vm3} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_1/
	${connect}${vm3} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_2/

	for i in {1..1}
	do

		${connect}${vm1} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_1/rep${i}/
		${connect}${vm1} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_2/rep${i}/
		${connect}${vm2} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_1/rep${i}/
		${connect}${vm2} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_2/rep${i}/
		${connect}${vm3} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_1/rep${i}/
		${connect}${vm3} mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_2/rep${i}/

		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/MW4/rep${i}/
		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/MW5/rep${i}/

		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_1/rep${i}/
		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_2/rep${i}/
		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_1/rep${i}/
		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_2/rep${i}/
		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_1/rep${i}/
		mkdir Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_2/rep${i}/
	
		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do

				memtierOutput1="Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_1/rep${i}/output"
		        	memtierOutput2="Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_2/rep${i}/output"
				memtierOutput3="Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_1/rep${i}/output"
		        	memtierOutput4="Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_2/rep${i}/output"
				memtierOutput5="Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_1/rep${i}/output"
		        	memtierOutput6="Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_2/rep${i}/output"

				cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s false -m ${server6}:11211 ${server7}:11211 ${server8}:11211"
				cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s false -m ${server6}:11211 ${server7}:11211 ${server8}:11211"

				cmdMemtierFirst="${cmd50} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
				cmdMemtierSecond="${cmd50} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

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
				scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/MW4/rep${i}/
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/MW5/rep${i}/
			done
		done

	
	${connect}${vm4} rm -r results/ 
	${connect}${vm5} rm -r results/ 

	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_1/rep${i}/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_1/rep${i}/
	scp -r arinaldi@${vm1}:/home/arinaldi/Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_2/rep${i}/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/VM1_2/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_1/rep${i}/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_1/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_2/rep${i}/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/VM2_2/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_1/rep${i}/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_1/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_2/rep${i}/. /home/andrea/Baseline6/50Set50Get_S3_MW2_W${wt}/VM3_2/rep${i}/
	echo "Done repetition " ${i}
	done
done


