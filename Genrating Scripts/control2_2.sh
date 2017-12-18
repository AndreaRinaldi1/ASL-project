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

port=11211

cmdSet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=1:0"
cmdGet="memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=${port} --ratio=0:1"

cmdRepopulate8="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate8Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.7 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=900 --clients=1 --threads=1 --hide-histogram"
cmdRepopulate7="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --requests=allkeys --clients=1 --threads=1 --hide-histogram"
cmdRepopulate7Prime="memtier_benchmark-master/memtier_benchmark --server=10.0.0.8 --port=11211 --protocol=memcache_text --ratio=1:0 --expiry-range=9999-10000 --key-maximum=10000 --data-size=1024 --test-time=900 --clients=1 --threads=1 --hide-histogram"

server8="10.0.0.7"
server7="10.0.0.8"
time=80
time2=15

#Check if there is an argument to the script
if [[ $# > 0 ]]; then
        server="$1"
fi

#Check if there is a 2nd argument to the script
if [[ $# > 1 ]]; then
	time="$2"
fi

#define parameter ranges
clients=(1 4 8 12 16 20 24 28 32 40 50)
threads=(1)

mkdir Baseline2/
mkdir Baseline2/2.2/
${connect}${vm2} mkdir Baseline2/
${connect}${vm2} mkdir Baseline2/2.2/
mkdir Baseline2/2.2/Set/
mkdir Baseline2/2.2/Set1/
mkdir Baseline2/2.2/Set2/
${connect}${vm2} mkdir Baseline2/2.2/Set/
${connect}${vm2} mkdir Baseline2/2.2/Set1/
${connect}${vm2} mkdir Baseline2/2.2/Set2/
mkdir Baseline2/2.2/Server7/
mkdir Baseline2/2.2/Server7/Set/
mkdir Baseline2/2.2/Server8/
mkdir Baseline2/2.2/Server8/Set/
${connect}${vm7} mkdir Baseline2/
${connect}${vm8} mkdir Baseline2/
${connect}${vm7} mkdir Baseline2/2.2/
${connect}${vm8} mkdir Baseline2/2.2/
${connect}${vm7} mkdir Baseline2/2.2/Set/
${connect}${vm8} mkdir Baseline2/2.2/Set/
for i in {1..3}
do
        for c in "${clients[@]}"; do
                for th in "${threads[@]}"; do
                        #add parameters to the command
                        output1="Baseline2/2.2/Set1/Set${c}_${th}"
                        output2="Baseline2/2.2/Set2/Set${c}_${th}"
                        cmd1="${cmdSet} --server=${server8} --test-time=${time} --clients=${c} --threads=${th}"
                        cmd2="${cmdSet} --server=${server7} --test-time=${time} --clients=${c} --threads=${th}"
                        #run the command
                        echo $cmd1
			${connect}${vm2} "dstat --output Baseline2/2.2/Set/dstat${c}_${th}.csv 5 ${time2}" &	
			${connect}${vm7} "dstat --output Baseline2/2.2/Set/dstat${c}_${th}.csv 5 ${time2}" &
			${connect}${vm8} "dstat --output Baseline2/2.2/Set/dstat${c}_${th}.csv 5 ${time2}" &

			${connect}${vm2} "$cmd1 >> ${output1}.log 2>&1" &
			${connect}${vm2} "$cmd2 >> ${output2}.log 2>&1" 
			sleep 2

                done
        done
done
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.2/Set1/. /home/andrea/Baseline2/2.2/Set1/ 
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.2/Set2/. /home/andrea/Baseline2/2.2/Set2/ 
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.2/Set/. /home/andrea/Baseline2/2.2/Set/
scp -r arinaldi@${vm7}:/home/arinaldi/Baseline2/2.2/Set/. /home/andrea/Baseline2/2.2/Server7/Set/
scp -r arinaldi@${vm8}:/home/arinaldi/Baseline2/2.2/Set/. /home/andrea/Baseline2/2.2/Server8/Set/
echo "done"

sleep 10

mkdir Baseline2/2.2/Get/
mkdir Baseline2/2.2/Get1/
mkdir Baseline2/2.2/Get2/
${connect}${vm2} mkdir Baseline2/2.2/Get/
${connect}${vm2} mkdir Baseline2/2.2/Get1/
${connect}${vm2} mkdir Baseline2/2.2/Get2/
mkdir Baseline2/2.2/Server7/Get/
mkdir Baseline2/2.2/Server8/Get/
${connect}${vm7} mkdir Baseline2/2.2/Get/
${connect}${vm8} mkdir Baseline2/2.2/Get/

${connect}${vm2} $cmdRepopulate8 &
${connect}${vm2} $cmdRepopulate7 &
${connect}${vm2} $cmdRepopulate8Prime &
${connect}${vm2} $cmdRepopulate7Prime 



for i in {1..3}
do
        for c in "${clients[@]}"; do
                for th in "${threads[@]}"; do
                        #add parameters to the command
                        output1="Baseline2/2.2/Get1/Get${c}_${th}"
                        output2="Baseline2/2.2/Get2/Get${c}_${th}"
                        cmd1="${cmdGet} --server=${server8} --test-time=${time} --clients=${c} --threads=${th}"
                        cmd2="${cmdGet} --server=${server7} --test-time=${time} --clients=${c} --threads=${th}"
                        #run the command
                        echo $cmd1
			${connect}${vm2} "dstat --output Baseline2/2.2/Get/dstat${c}_${th}.csv 5 ${time2}" &	
			${connect}${vm7} "dstat --output Baseline2/2.2/Get/dstat${c}_${th}.csv 5 ${time2}" &
			${connect}${vm8} "dstat --output Baseline2/2.2/Get/dstat${c}_${th}.csv 5 ${time2}" &

			${connect}${vm2} "$cmd1 >> ${output1}.log 2>&1" &
			${connect}${vm2} "$cmd2 >> ${output2}.log 2>&1" 
			sleep 2

                done
        done
done
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.2/Get1/. /home/andrea/Baseline2/2.2/Get1/ 
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.2/Get2/. /home/andrea/Baseline2/2.2/Get2/ 
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.2/Set/. /home/andrea/Baseline2/2.2/Get/
scp -r arinaldi@${vm7}:/home/arinaldi/Baseline2/2.2/Get/. /home/andrea/Baseline2/2.2/Server7/Get/
scp -r arinaldi@${vm8}:/home/arinaldi/Baseline2/2.2/Get/. /home/andrea/Baseline2/2.2/Server8/Get/
echo "done"

