This project aims at automatizing the creation of a Layered Queuing Network of a microservice-based application. Application deployment should already be completed on a server, keeping the modeler in the dark about its functioning.

The application we modeled is the open-source Train Ticket Booking System available at https://github.com/FudanSELab/train-ticket. TTBS is structured in 69 containers deployed using docker.

We exploit the LQN to represent the resources used by the application. Resources utilization values are obtained polling the files found the directories related to the cgroup of the application. So, what we model is the resource utilization of each container. 

It is hard for a modeler to represent a great amount of containers, we model only the ones triggered by a given scenario.
The requests exchanged by the containers are discovered using tcpdump. 
