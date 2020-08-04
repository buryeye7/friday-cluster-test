FROM buryeye7/centos7-hdac-base

USER root
ENV HOME=/root
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64
ENV GOPATH=$HOME/go
ENV GOROOT=/usr/local/go
ENV PATH=$PATH:$HOME/.cargo/bin:$GOPATH/bin:$GOROOT/bin

RUN cmake -version
RUN gcc --version
RUN rustc --version

RUN yum -y update
RUN yum -y upgrade
RUN yum -y install expect
RUN yum -y install vim 
RUN yum -y install telnet
RUN yum -y install net-tools 

WORKDIR $GOPATH/src
RUN git clone https://github.com/hdac-io/friday
WORKDIR $GOPATH/src/friday
#RUN git checkout refactor/execute
#RUN git checkout v0.11.0
#RUN git checkout v0.9.0
RUN npm install -g assemblyscript@0.9.1
RUN make install
