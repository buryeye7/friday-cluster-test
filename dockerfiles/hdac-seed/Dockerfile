FROM buryeye7/hdac-base

USER root
ENV HOME=/root
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64
ENV GOPATH=$HOME/go
ENV GOROOT=/usr/local/go
ENV PATH=$PATH:$HOME/.cargo/bin:$GOPATH/bin:$GOROOT/bin

WORKDIR $HOME

WORKDIR $GOPATH/src
RUN git clone https://github.com/buryeye7/friday-cluster-test
WORKDIR $GOPATH/src/friday-cluster-test

RUN rm -rf $HOME/.nodef
RUN rm -rf $HOME/.clif
RUN mkdir -p $HOME/.nodef
RUN mkdir -p $HOME/.clif

EXPOSE 26656/tcp
EXPOSE 26657/tcp
EXPOSE 26660/tcp
EXPOSE 27017/tcp
EXPOSE 1317/tcp
EXPOSE 9090/tcp
EXPOSE 3000/tcp
EXPOSE 6060/tcp

ENTRYPOINT ["./scripts/start-seed.sh"]
