# Advanced Systems Lab

In this project we create a middleware that is part of a complex computer and software system.
The goal is to evaluate the performance and the beahavior of the system under different configurations (number of clients, number of middlewares, threads ...). This is done by carrying out experiments on Microsoft Azure, collecting data and analyzing these measurements.
Furthermore, the system will be modeled in different ways (M/M/1, M/M/m and Queuing Network) in order to understands how well the theoretical implementations differs from the real one, what are the advantages of creating a model and its limits.

## Overview

The root directory contains the source code, the final Report and the aggregated information of the data collected from the experiments on the Cloud. It is also included the original outputs of the memtier clients for every experiment, but the data gathered from the instrumentation of the middleware is omitted due to data volume submission conststraints. Consequently, for the data related to the middleware, just those needed to create the plots, graphs and tables in the report are uploaded. In case of clarifications, I still have the original raw data though.

## The Source Code

* The `RunMW` class is the starting point of the middleware: the arguments from command line are parsed and processed, and the `MyMiddleware` thread is run.

* The `MyMiddleware` class is where the middleware is initialized. The worker threads and the net threads are created and started. This is where the connections between clients and middleware are estabilished and their channel registered to the Selecor. At the end of the experiment, in this class, there is a `ShutdownHook` to collect the data stored in the variables of the worker threads, of the `ClientHandler` and the `ServerHandler`, to finally write the information to files.

* The `ClientHandler` class implements the Net Thread, that is where the clients send their requests to. This singleton instance makes use of non-blocking I/O for managing the connections with the clients, so that, when one of them is ready to write, the message is read from the channel into the buffer and a new `Job` is created. Lastly, the net thread puts this new job into the queue, and goes on handling the next incoming request from the clients.

* The `WorkerThread` takes a single request out of the queue, parse it and process it following a different path according to its type. In case of a Set request, it is replicated to all the servers and then all the responses are fetched. If the request is a Get, it is simply forwarded to one of the servers, while if it is a multi-get we distinguish two cases. If sharding is enabled, the message is splitted in smaller requests and these forwarded to the servers accordingly, while if it is not enabled, the whole request is sent to one single server. Lastly, when the responses have been collected, the worker thread sends the reply to the client.

* The `ServerHandler` class provides the communication interface between the worker thread and the server, meaning that it manages the activities of sending and receiving the message to and from the servers.

* The `Job` class provides the structure for the creation of the requests object that the net thread puts in the queue and that will be taken out and processed by the worker threads.


## Run the experiments

### Prerequisites

* [Memtier](https://github.com/RedisLabs/memtier_benchmark/)
* [Memcached](https://github.com/memcached/memcached)

### How to run

1. Specify the directory path where you want to save the data collected through the instrumentation of the middleware in the local variable `prefixNS` of the `MyMiddleware` class
2. Run memcached: `memcached -t <number_of_threads> -p <port>` 
3. Run the middleware: `java -jar middleware-17941626.jar -l <IP_address_MW> -p <port_MW> -t <num_of_workerThreads> -s <sharding_boolean> -m <IP_address_server>:<port_server>` 
4. Run memtier: `memtier_benchmark-master/memtier_benchmark --data-size=1024 --protocol=memcache_text --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram --port=<port_MW> --server=<IP_address_MW> --test-time=<time>`


## How to navigate the data

* **Section 2**: The folder divides in two other folders accoring to the sub-section to consider (2.1 / 2.2). For every virtual machine (and for every instance of memtier in case of Section 2.2) there is a folder that contains the outputs of memtier, labeled as `Get<numOfClients>_<numOfThreads>` and equivalently for Set and dstat output. Moreover every one of these folders has a file `results.txt` where the average throughput and response time are reported for each repetition of the experiment. Lastly, there is also one folder for each server VM with the dstat results for every experiments.

* **Sections 3, 4, 5**: each of this section might be divided in other folders depending on how many subsections there are, and if we ran experiments both for Get and Set requests or not. In any case, at the "leaf" of these folders there are always two folders: one named aggregated Data that contains, as the name suggests, the aggregated information collected from the experiments on the Cloud that are necessary to create the plots and tables of the report (throughput, response time, queue length, service time, waiting time ...). The other folder, named Client, contains, as already mentioned at the beginning, the memtier outputs for every VM (or memtier instance of every VM).
The naming convention for the files is the following: if the file's name is `Set_C20_T1_W8_R2.log`, this means that the experiment is a write-only one, with 20 virtual clients per thread, 1 thread, 8 worker threads and it is the second repetition. For the Section 5, "Set" is replaced by "output" as we generate one Set request every Multi-get, and the K in the file name stands for "number of keys" in a multi-get request, and its is followed by that value. 

* **Section 6**: depending on the type of workload we have the folder named "Write", "Read" or "50Set50Get". The letter "S" that follows stands for the number of servers used, "MW" the number of middlewares and "W" the number of worker threads, and each of these expressions is followed by the relative number. Inside each of these folders there is a file `results.txt` that reports the throughput and response time, and there are 6 folders named according the convention `VM<virtualMachineNumber>_<memtierInstanceNumber>`.

* **Section 7**: the folder is divided is two sub-folders: MM1 and MMm. The file's name in them follow the same convention as before ("C" being the number of clients and "W" the number of worker threads). The data needed to produce these models and files can be found in Section 4, and Section 3 for the Network of Queues.


