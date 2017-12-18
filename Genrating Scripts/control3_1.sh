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

port=4541

cmdSet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=1:0"
cmdGet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=0:1"

middleware="10.0.0.11"
server="10.0.0.7"
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
clients=(1 4 8 12 16 20 24 28 32 45 60 85 110)
threads=(2)
workers=(8 16 32 64)


${connect}${vm1} mkdir Set/
${connect}${vm1} mkdir Set/rep1/
${connect}${vm1} mkdir Set/rep2/
${connect}${vm1} mkdir Set/rep3/
mkdir Set/
mkdir Set/rep1/
mkdir Set/rep2/
mkdir Set/rep3/
mkdir Set/rep1/MW/
mkdir Set/rep2/MW/
mkdir Set/rep3/MW/
mkdir Set/rep1/memtier/
mkdir Set/rep2/memtier/
mkdir Set/rep3/memtier/

for wt in "${workers[@]}"; do

	for i in {1..3}
	do
		${connect}${vm5} mkdir results/
	
		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do
				mkdir Set/rep${i}/MW/Set_C${c}_T${th}_W${wt}_R${i}/

				memtierOutput="Set/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
                        	
				cmdMemtier="${cmdSet} --server=${middleware} --test-time=${time} --clients=${c} --threads=${th}"
	                        cmdMWstart="java -jar middleware-17941626.jar -l ${middleware} -p ${port} -t ${wt} -s false -m ${server}:11211"
			
				${connect}${vm5} $cmdMWstart & 
				
				sleep 10	
				echo $cmdMemtier
				${connect}${vm1} "$cmdMemtier >> ${memtierOutput}.log 2>&1"
				
				sleep 2
				echo "kill MW"
				${connect}${vm5} pkill -n java
				
				sleep 2	
				echo "copy files"
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Set/rep${i}/MW/Set_C${c}_T${th}_W${wt}_R${i}/
				scp -r arinaldi@${vm1}:/home/arinaldi/Set/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}.log /home/andrea/Set/rep${i}/memtier/
				
			done
		done

		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	echo "Done all workers for repetition " ${i}
done

echo "Done Set"


cmdRepopulate="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate2="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=600 --clients=1 --threads=1 --hide-histogram"


${connect}${vm1} mkdir Get/
${connect}${vm1} mkdir Get/rep1/
${connect}${vm1} mkdir Get/rep2/
${connect}${vm1} mkdir Get/rep3/
mkdir Get/
mkdir Get/rep1/
mkdir Get/rep2/
mkdir Get/rep3/
mkdir Get/rep1/MW/
mkdir Get/rep2/MW/
mkdir Get/rep3/MW/
mkdir Get/rep1/memtier/
mkdir Get/rep2/memtier/
mkdir Get/rep3/memtier/
for wt in "${workers[@]}"; do   
        
	${connect}${vm1} "$cmdRepopulate"
	${connect}${vm1} "$cmdRepopulate2"
	
	for i in {1..3}
	do
                ${connect}${vm5} mkdir results/
                
                for c in "${clients[@]}"; do
			for th in "${threads[@]}"; do
                         	mkdir Get/rep${i}/MW/Get_C${c}_T${th}_W${wt}_R${i}/
			 	memtierOutput="Get/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}"
                                cmdMemtier="${cmdGet} --server=${middleware} --test-time=${time} --clients=${c} --threads=${th}"
                                cmdMWstart="java -jar middleware-17941626.jar -l ${middleware} -p ${port} -t ${wt} -s false -m ${server}:11211"
                                
                                ${connect}${vm5} $cmdMWstart & 
				sleep 10
				echo $cmdMemtier
				${connect}${vm1} "$cmdMemtier >> ${memtierOutput}.log 2>&1"
				sleep 2
				echo "kill MW"
                                ${connect}${vm5} pkill -n java
				sleep 2
				echo "copy files"
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Get/rep${i}/MW/Get_C${c}_T${th}_W${wt}_R${i}/
				scp -r arinaldi@${vm1}:/home/arinaldi/Get/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}.log /home/andrea/Get/rep${i}/memtier/
                        done
                done
                ${connect}${vm5} rm -r results/
                echo "Done all clients for worker " ${wt} " for repetition " ${i}
        done

        echo "Done all workers for repetition " ${i}
	
done
echo "Done Get"

