# Project 3 – Chord Protocol
**COP5615 - Distributed Operating Systems Principles**

---
## Group Info

* [Ankit Soni- 8761-9158](http://github.com/ankitprahladsoni)
* [Kumar Kunal- 5100-5964](http://github.com/kunal4892)

---

## What is working?  

* The chord protocol is implemented using the APIs(join, stabilize...) mentioned in the research paper. The implementation is working as expected. There is only one submission that contains the implementation of the
bonus as well.

* The operation of hashing as mentioned in the requirements followed by m bit reductions
caused a lot of collisions while establishing unique node ids. To avert this problem, the project uses the random number approach.

* The maximum number of nodes in the chord 1000 nodes with 100 messages each. The average number of hops
for a message to reach the destination was in the range of [3, 5]. Averaged over 10 runs, the value turned to be
3.93 hops. Therefore, this means that for any node to search for any content, the chord protocol takes an average of 3.93 hops. This shows that lookup takes order of log n time.

* The maximun number of nodes tested could be more than 1000, but the time taken to stabilize these many nodes is significantly higher. The application works better for higher number of messages.
---

## Instructions(Bonus is included):

* The input provided (as command line to the program) will be of the form:

>$ mix run project3.exs numNodes numMessages

numNodes -> Required number of nodes to be set up in a chord  
numMessages -> Number of messages each node sends for lookups    
   
* The input for Bonus will be of the form:  
   
>$ mix run project3.exs numNodes numMessages numDeleteNodes   

numNodes -> Required number of nodes to be set up in a chord  
numMessages -> Number of messages each node sends for lookups  
numDeleteNodes -> Number of nodes to be deleted from the established nodes(failure model)   

---

## Result of running:

>$ *mix run project3.exs 1000 10   
Average hops for a message: 3.218
 ---
 
## Result of running(Bonus):

>$ *mix run project3.exs 1000 100 10   
Average hops for a message: 3.310  
 ---


