FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y tmux wget curl git
RUN apt-get install -y libgmp3-dev
# cairo was tested on python 3.7
RUN apt-get install -y python3.7 python3.7-dev python3-pip
# copy the current repository to the container and store it at /usr/src/app - you can learn more about this convention here: https://en.wikipedia.org/wiki/Unix_filesystem#Conventional_directory_layout
# we first copy the requirements file only, to use the docker cache effectively
COPY ./requirements.txt /usr/src/app/requirements.txt
# install the dependencies
RUN python3.7 -m pip install pip
RUN python3.7 -m pip install -r /usr/src/app/requirements.txt
# we put the copying of the complete repo to the end of the container to use the docker cache effectively
COPY . /usr/src/app
WORKDIR /usr/src/app
RUN (cd cairo && make build)
RUN (cd cairo && make test)
CMD ["bash"]
