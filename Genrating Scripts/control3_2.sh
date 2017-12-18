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

port=4560

cmdSet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=1:0"
cmdGet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=0:1"

middleware4="10.0.0.10"
middleware5="10.0.0.11"
server="10.0.0.8"

time=80 #80
time2=7 #7
time3=5 #5

#Check if there is an argument to the script
if [[ $# > 0 ]]; then
        server="$1"
fi

#Check if there is a 2nd argument to the script
if [[ $# > 1 ]]; then
	time="$2"
fi

#define parameter ranges
clients=(105 85 60 45 32 28 24 20 16 12 8 4 1)
threads=(1)
workers=(64 32 16 8)

mkdir Set/
mkdir Set/MW4/
mkdir Set/MW5/

mkdir Set/VM1_1/
mkdir Set/VM1_2/


#${connect}${vm4} mkdir Set/
#${connect}${vm4} mkdir Set/dstat/

#${connect}${vm5} mkdir Set/
#${connect}${vm5} mkdir Set/dstat/

${connect}${vm1} mkdir Set/
${connect}${vm1} mkdir Set/dstat/

${connect}${vm7} mkdir Set/
mkdir Set/dstatServer/
mkdir Set/dstatClient/
#mkdir Set/MW4/dstat/
#mkdir Set/MW5/dstat/


${connect}${vm1} mkdir Set/VM1_1/
${connect}${vm1} mkdir Set/VM1_2/

${connect}${vm1} mkdir Set/VM1_1/rep1/
${connect}${vm1} mkdir Set/VM1_2/rep1/
${connect}${vm1} mkdir Set/VM1_1/rep2/
${connect}${vm1} mkdir Set/VM1_2/rep2/
${connect}${vm1} mkdir Set/VM1_1/rep3/
${connect}${vm1} mkdir Set/VM1_2/rep3/

mkdir Set/MW4/rep1/
mkdir Set/MW5/rep1/
mkdir Set/MW4/rep2/
mkdir Set/MW5/rep2/
mkdir Set/MW4/rep3/
mkdir Set/MW5/rep3/
mkdir Set/VM1_1/rep1/
mkdir Set/VM1_2/rep1/
mkdir Set/VM1_1/rep2/
mkdir Set/VM1_2/rep2/
mkdir Set/VM1_1/rep3/
mkdir Set/VM1_2/rep3/

for wt in "${workers[@]}"; do

	for i in {1..3}
	do
		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do

				mkdir Set/MW4/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/
				mkdir Set/MW5/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/

				memtierOutput1="Set/VM1_1/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
		        	memtierOutput2="Set/VM1_2/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}"
			
				cmdMemtierFirst="${cmdSet} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
				cmdMemtierSecond="${cmdSet} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

	                        cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s false -m ${server}:11211"
				cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s false -m ${server}:11211"

				${connect}${vm4} $cmdMWstart4 & 
				${connect}${vm5} $cmdMWstart5 &
				
				sleep 10	
				echo $cmdMemtierFirst

				${connect}${vm1} "dstat --output Set/dstat/dstat${c}_${wt}.csv 10 ${time2}" &
				#${connect}${vm4} "dstat --output Set/dstat/dstat${c}_${wt}.csv 14 ${time3}" &
				#${connect}${vm5} "dstat --output Set/dstat/dstat${c}_${wt}.csv 14 ${time3}" &
				${connect}${vm7} "dstat --output Set/dstat${c}_${wt}.csv 10 ${time2}" &				

				${connect}${vm1} "$cmdMemtierFirst >> ${memtierOutput1}.log 2>&1" &
				${connect}${vm1} "$cmdMemtierSecond >> ${memtierOutput2}.log 2>&1" 
			
				sleep 2
				echo "kill MW"

				${connect}${vm4} pkill -n java &
				${connect}${vm5} pkill -n java

				sleep 2	
				echo "copy files"

				scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Set/MW4/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/ 
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Set/MW5/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}/
				scp -r arinaldi@${vm1}:/home/arinaldi/Set/VM1_1/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}.log /home/andrea/Set/VM1_1/rep${i}/
				scp -r arinaldi@${vm1}:/home/arinaldi/Set/VM1_2/rep${i}/Set_C${c}_T${th}_W${wt}_R${i}.log /home/andrea/Set/VM1_2/rep${i}/
			done
		done

		${connect}${vm4} rm -r results/ 
		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	echo "Done all repetition for worker " ${wt}
done

echo "Done Set"

scp -r arinaldi@${vm1}:/home/arinaldi/Set/dstat/. /home/andrea/Set/dstatClient/
#scp -r arinaldi@${vm4}:/home/arinaldi/Set/dstat/. /home/andrea/Set/MW4/dstat/
#scp -r arinaldi@${vm5}:/home/arinaldi/Set/dstat/. /home/andrea/Set/MW5/dstat/
scp -r arinaldi@${vm7}:/home/arinaldi/Set/. /home/andrea/Set/dstatServer/

cmdRepopulate="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate2="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=600 --clients=1 --threads=1 --hide-histogram"

sleep 10

mkdir Get/
mkdir Get/MW4/
mkdir Get/MW5/

mkdir Get/VM1_1/
mkdir Get/VM1_2/

#${connect}${vm4} mkdir Get/
#${connect}${vm4} mkdir Get/dstat/

#${connect}${vm5} mkdir Get/
#${connect}${vm5} mkdir Get/dstat/

${connect}${vm1} mkdir Get/
${connect}${vm1} mkdir Get/dstat/

${connect}${vm7} mkdir Get/
mkdir Get/dstatServer/
mkdir Get/dstatClient/
#mkdir Get/MW4/dstat/
#mkdir Get/MW5/dstat/


${connect}${vm1} mkdir Get/VM1_1/
${connect}${vm1} mkdir Get/VM1_2/

${connect}${vm1} mkdir Get/VM1_1/rep1/
${connect}${vm1} mkdir Get/VM1_2/rep1/
${connect}${vm1} mkdir Get/VM1_1/rep2/
${connect}${vm1} mkdir Get/VM1_2/rep2/
${connect}${vm1} mkdir Get/VM1_1/rep3/
${connect}${vm1} mkdir Get/VM1_2/rep3/

mkdir Get/MW4/rep1/
mkdir Get/MW5/rep1/
mkdir Get/MW4/rep2/
mkdir Get/MW5/rep2/
mkdir Get/MW4/rep3/
mkdir Get/MW5/rep3/
mkdir Get/VM1_1/rep1/
mkdir Get/VM1_2/rep1/
mkdir Get/VM1_1/rep2/
mkdir Get/VM1_2/rep2/
mkdir Get/VM1_1/rep3/
mkdir Get/VM1_2/rep3/

for wt in "${workers[@]}"; do
	${connect}${vm1} "$cmdRepopulate"
	${connect}${vm1} "$cmdRepopulate2"

	for i in {1..3}
	do
		${connect}${vm4} mkdir results/
		${connect}${vm5} mkdir results/

		for c in "${clients[@]}"; do
        		for th in "${threads[@]}"; do

				mkdir Get/MW4/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/
				mkdir Get/MW5/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/

				memtierOutput1="Get/VM1_1/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}"
		        	memtierOutput2="Get/VM1_2/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}"
			
				cmdMemtierFirst="${cmdGet} --server=${middleware4} --test-time=${time} --clients=${c} --threads=${th}"
				cmdMemtierSecond="${cmdGet} --server=${middleware5} --test-time=${time} --clients=${c} --threads=${th}"

	                        cmdMWstart4="java -jar middleware-17941626.jar -l ${middleware4} -p ${port} -t ${wt} -s false -m ${server}:11211"
				cmdMWstart5="java -jar middleware-17941626.jar -l ${middleware5} -p ${port} -t ${wt} -s false -m ${server}:11211"

				${connect}${vm4} $cmdMWstart4 & 
				${connect}${vm5} $cmdMWstart5 &

				sleep 10	
				echo $cmdMemtierFirst

				${connect}${vm1} "dstat --output Get/dstat/dstat${c}_${wt}.csv 10 ${time2}" &	
				#${connect}${vm4} "dstat --output Get/dstat/dstat${c}_${wt}.csv 14 ${time3}" &
				#${connect}${vm5} "dstat --output Get/dstat/dstat${c}_${wt}.csv 14 ${time3}" &
				${connect}${vm7} "dstat --output Get/dstat${c}_${wt}.csv 10 ${time2}" &
				
				${connect}${vm1} "$cmdMemtierFirst >> ${memtierOutput1}.log 2>&1" &
				${connect}${vm1} "$cmdMemtierSecond >> ${memtierOutput2}.log 2>&1" 
			
				sleep 2
				echo "kill MW"

				${connect}${vm4} pkill -n java &
				${connect}${vm5} pkill -n java

				sleep 2	
				echo "copy files"

				scp -r arinaldi@${vm4}:/home/arinaldi/results/. /home/andrea/Get/MW4/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/ 
				scp -r arinaldi@${vm5}:/home/arinaldi/results/. /home/andrea/Get/MW5/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}/
				scp -r arinaldi@${vm1}:/home/arinaldi/Get/VM1_1/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}.log /home/andrea/Get/VM1_1/rep${i}/
				scp -r arinaldi@${vm1}:/home/arinaldi/Get/VM1_2/rep${i}/Get_C${c}_T${th}_W${wt}_R${i}.log /home/andrea/Get/VM1_2/rep${i}/
			done
		done

		${connect}${vm4} rm -r results/ 
		${connect}${vm5} rm -r results/
		echo "Done all clients for worker " ${wt} " for repetition " ${i}
       	done

	echo "Done all repetition for worker " ${wt}
done

echo "Done Get"
scp -r arinaldi@${vm1}:/home/arinaldi/Get/dstat/. /home/andrea/Get/dstatClient/
#scp -r arinaldi@${vm4}:/home/arinaldi/Get/dstat/. /home/andrea/Get/MW4/dstat/
#scp -r arinaldi@${vm5}:/home/arinaldi/Get/dstat/. /home/andrea/Get/MW5/dstat/
scp -r arinaldi@${vm7}:/home/arinaldi/Get/. /home/andrea/Get/dstatServer/

