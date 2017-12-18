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

port=4574

cmdSet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=1:0"

middleware4="10.0.0.10"
middleware5="10.0.0.11"
server6="10.0.0.4"
server7="10.0.0.8"
server8="10.0.0.7"

time=80

#Check if there is an argument to the script
if [[ $# > 0 ]]; then
        server="$1"
fi

#Check if there is a 2nd argument to the script
if [[ $# > 1 ]]; then
	time="$2"
fi

#define parameter ranges
clients=(1 4 8 12 16 20 24 28 32 40)
threads=(1)
workers=(8 16 32 64)

mkdir Set/
mkdir Set1/
mkdir Set2/
mkdir Set3/
mkdir Set4/
mkdir Set5/
mkdir Set6/

${connect}${vm1} mkdir Set1/
${connect}${vm1} mkdir Set2/
${connect}${vm2} mkdir Set3/
${connect}${vm2} mkdir Set4/
${connect}${vm3} mkdir Set5/
${connect}${vm3} mkdir Set6/

for i in {1..3}
do
	${connect}${vm1} mkdir Set1/rep${i}/
	${connect}${vm1} mkdir Set2/rep${i}/
	${connect}${vm2} mkdir Set3/rep${i}/
	${connect}${vm2} mkdir Set4/rep${i}/
	${connect}${vm3} mkdir Set5/rep${i}/
	${connect}${vm3} mkdir Set6/rep${i}/

	mkdir Set1/rep${i}/
	mkdir Set2/rep${i}/

	mkdir Set3/rep${i}/
	mkdir Set4/rep${i}/

	mkdir Set5/rep${i}/
	mkdir Set6/rep${i}/
	
	mkdir Set/rep${i}/
	mkdir Set/rep${i}/MW4/
	mkdir Set/rep${i}/MW5/

	for wt in "${workers[@]}"; do

		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do

				mkdir Set/rep${i}/MW4/Set_C${c}_T${th}_W${wt}_R${i}/
				mkdir Set/rep${i}/MW5/Set_C${c}_T${th}_W${wt}_R${i}/
				
				memtierOutput1="Set1/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
                        	memtierOutput2="Set2/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
				memtierOutput3="Set3/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
                        	memtierOutput4="Set4/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
				memtierOutput5="Set5/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
                        	memtierOutput6="Set6/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"

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

				sleep 2
				echo "kill MW"

				${connect}${vm4} pkill -n java &
				${connect}${vm5} pkill -n java

				sleep 2	
				echo "copy files"

				scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Set/rep${i}/MW4/Set_C${c}_T${th}_W${wt}_R${i}/ 
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Set/rep${i}/MW5/Set_C${c}_T${th}_W${wt}_R${i}/
			done

		done

		${connect}${vm4} rm -r results/ 
		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	scp -r arinaldi@${vm1}:/home/arinaldi/Set1/rep${i}/. /home/andrea/Set1/rep${i}/ 
	scp -r arinaldi@${vm1}:/home/arinaldi/Set2/rep${i}/. /home/andrea/Set2/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Set3/rep${i}/. /home/andrea/Set3/rep${i}/
	scp -r arinaldi@${vm2}:/home/arinaldi/Set4/rep${i}/. /home/andrea/Set4/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Set5/rep${i}/. /home/andrea/Set5/rep${i}/
	scp -r arinaldi@${vm3}:/home/arinaldi/Set6/rep${i}/. /home/andrea/Set6/rep${i}/
	echo "Done all workers for repetition " ${i}
done

echo "Done Set"

