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

server8="10.0.0.7"
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
threads=(2)

mkdir Baseline2/
mkdir Baseline2/2.1/
${connect}${vm1} mkdir Baseline2/
${connect}${vm2} mkdir Baseline2/
${connect}${vm3} mkdir Baseline2/
${connect}${vm8} mkdir Baseline2/
${connect}${vm1} mkdir Baseline2/2.1/
${connect}${vm2} mkdir Baseline2/2.1/
${connect}${vm3} mkdir Baseline2/2.1/
${connect}${vm8} mkdir Baseline2/2.1/
mkdir Baseline2/2.1/Server/
mkdir Baseline2/2.1/Server/Set/
mkdir Baseline2/2.1/Set1/
mkdir Baseline2/2.1/Set2/
mkdir Baseline2/2.1/Set3/
${connect}${vm1} mkdir Baseline2/2.1/Set/
${connect}${vm2} mkdir Baseline2/2.1/Set/
${connect}${vm3} mkdir Baseline2/2.1/Set/
${connect}${vm8} mkdir Baseline2/2.1/Set/

for i in {1..3}
do
        for c in "${clients[@]}"; do
                for th in "${threads[@]}"; do
                        #add parameters to the command
                        output="Baseline2/2.1/Set/Set${c}_${th}"
                        cmd="${cmdSet} --server=${server8} --test-time=${time} --clients=${c} --threads=${th}"
                        #run the command
                        echo $cmd

			${connect}${vm1} "dstat --output Baseline2/2.1/Set/dstat${c}_${th}.csv 5 ${time2}" &
			${connect}${vm2} "dstat --output Baseline2/2.1/Set/dstat${c}_${th}.csv 5 ${time2}" &			
			${connect}${vm3} "dstat --output Baseline2/2.1/Set/dstat${c}_${th}.csv 5 ${time2}" &
			${connect}${vm8} "dstat --output Baseline2/2.1/Set/dstat${c}_${th}.csv 5 ${time2}" &

			${connect}${vm1} "$cmd >> ${output}.log 2>&1" &
			${connect}${vm2} "$cmd >> ${output}.log 2>&1" &
			${connect}${vm3} "$cmd >> ${output}.log 2>&1" 
			
			sleep 2
                done
        done
done
scp -r arinaldi@${vm1}:/home/arinaldi/Baseline2/2.1/Set/. /home/andrea/Baseline2/2.1/Set1/ 
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.1/Set/. /home/andrea/Baseline2/2.1/Set2/
scp -r arinaldi@${vm3}:/home/arinaldi/Baseline2/2.1/Set/. /home/andrea/Baseline2/2.1/Set3/
scp -r arinaldi@${vm8}:/home/arinaldi/Baseline2/2.1/Set/. /home/andrea/Baseline2/2.1/Server/Set/

echo "done"

sleep 10

mkdir Baseline2/2.1/Get1/
mkdir Baseline2/2.1/Get2/
mkdir Baseline2/2.1/Get3/
${connect}${vm1} mkdir Baseline2/2.1/Get/
${connect}${vm2} mkdir Baseline2/2.1/Get/
${connect}${vm3} mkdir Baseline2/2.1/Get/
${connect}${vm8} mkdir Baseline2/2.1/Get/
mkdir Baseline2/2.1/Server/Get/

${connect}${vm2} $cmdRepopulate8 &
${connect}${vm3} $cmdRepopulate8Prime

for i in {1..3}
do
        for c in "${clients[@]}"; do
                for th in "${threads[@]}"; do
                        #add parameters to the command
                        output="Baseline2/2.1/Get/Get${c}_${th}"
                        cmd="${cmdGet} --server=${server8} --test-time=${time} --clients=${c} --threads=${th}"
                        #run the command
                        echo $cmd

			${connect}${vm1} "dstat --output Baseline2/2.1/Get/dstat${c}_${th}.csv 5 ${time2}" &
			${connect}${vm2} "dstat --output Baseline2/2.1/Get/dstat${c}_${th}.csv 5 ${time2}" &			
			${connect}${vm3} "dstat --output Baseline2/2.1/Get/dstat${c}_${th}.csv 5 ${time2}" &
			${connect}${vm8} "dstat --output Baseline2/2.1/Get/dstat${c}_${th}.csv 5 ${time2}" &

			${connect}${vm1} "$cmd >> ${output}.log 2>&1" &
			${connect}${vm2} "$cmd >> ${output}.log 2>&1" &
			${connect}${vm3} "$cmd >> ${output}.log 2>&1" 
			sleep 2
                done
        done
done
scp -r arinaldi@${vm1}:/home/arinaldi/Baseline2/2.1/Get/. /home/andrea/Baseline2/2.1/Get1/ 
scp -r arinaldi@${vm2}:/home/arinaldi/Baseline2/2.1/Get/. /home/andrea/Baseline2/2.1/Get2/
scp -r arinaldi@${vm3}:/home/arinaldi/Baseline2/2.1/Get/. /home/andrea/Baseline2/2.1/Get3/
scp -r arinaldi@${vm8}:/home/arinaldi/Baseline2/2.1/Get/. /home/andrea/Baseline2/2.1/Server/Get/

echo "done"


