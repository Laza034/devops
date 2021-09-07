DOCKER APPLICATION DOCUMENTATION

TOOLS:

Docker version 19.03.13, build 4484c46d9d

REQUIREMENTS:

Inside of the /app directory is the code for a static web application written in the Go programming language. The application is not currently containerized, and cannot currently be deployed in a container platform such as kubernetes.
This task is aimed at demonstrating knowledge of containerization.

SOLUTION:

Docker APP was containerized using 2 approaches. Standard and multistage in order to minimize image size(25.5MB).
Both Standard and multistage dockerfiles are present in this repo for review.
Image can be pulled from my docker hub:  laza034/devops:multistage 
