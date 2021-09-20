FROM logicmoo/logicmoo_starter_image

USER root
LABEL maintainer = "logicmoo@gmail.com"
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND noninteractive
ARG --security-opt seccomp:unconfined

# SSHD
EXPOSE 22    
# Apache HTTP 
#EXPOSE 80    
# Apache SSL 
#EXPOSE 443 4443
# Ngynx
EXPOSE 4801   
# Butterfly Logins
EXPOSE 4180
# SWISH
EXPOSE 3020
# Eggdrop
EXPOSE 3334
# MUD Plain Text (HTTPS/HTTP/TELNET)
EXPOSE 14100  4100  4000   
# MUD with Debug (HTTPS/HTTP/TELNET)
EXPOSE 14101  4101  4001   
# MUD with Graphics (HTTPS/HTTP/TELNET)
EXPOSE 14102  4102  4002  
# WAM-CL REPL (HTTPS/HTTP/TELNET)
EXPOSE 14103  4103  4003  
# NOMIC MU (HTTPS/HTTP/TELNET)
EXPOSE 14104  4104  4004   
#  Shared SWIPL ?-  (HTTPS/HTTP/TELNET)
EXPOSE 14123  4123  4023  
# Non-Shared SWIPL ?- (HTTPS/HTTP/TELNET)
EXPOSE 14125  4125  4025   

EXPOSE 4090 4091


MAINTAINER RUN if [ ! -z "$LOGICMOO_EXTRAS" ]; \
 then \
  curl -O http://mirror.umd.edu/eclipse/technology/epp/downloads/release/2020-06/R/eclipse-java-2020-06-R-linux-gtk-x86_64.tar.gz \
  && tar -zxvf eclipse-java-2020-06-R-linux-gtk-x86_64.tar.gz -C /usr/ \
  && ln -s /usr/eclipse/eclipse /usr/bin/eclipse \
  && rm -f eclipse-java-2020-06-R-linux-gtk-x86_64.tar.gz \
 fi


ENV HOME /root

COPY docker/rootfs /

COPY packs_web/butterfly /tmp/butterfly/
RUN cd /tmp/butterfly/ && pip3 install .

MAINTAINER RUN apt-get update && apt-get install -y --allow-unauthenticated \
  nginx-common nginx nginx-core  libnginx-mod-http-geoip libnginx-mod-http-image-filter \
  libnginx-mod-http-xslt-filter libnginx-mod-mail libnginx-mod-stream \
  supervisor apache2 nmap x11-apps vim eggdrop default-jdk default-jre \
  iproute2 libgd3 libgeoip1 libmnl0 libwebp6 libxslt1.1 \
 \
 python3-gevent \
 python3-flask-api \
 iputils-ping \
 iputils-arping \
 nfs-kernel-server \
 nfs-common \
 rpcbind \
 telnet \
 traceroute \
 inotify-tools \
 ant \
 swig \
 flex \
 libllvm8 \
 lsb-release \
 tzdata \
 gosu \
 zlib1g-dev \
 zlib1g \
 zip \
 yarn \
 #xvnc4viewer \
 xvfb \
 xtrans-dev \
 xterm \
 xorg-sgml-doctools \
 xfonts-base \
 xdotool \
 xauth \
 x11vnc \
 x11-utils \
 x11proto-xinerama-dev \
 x11proto-xext-dev \
 x11proto-dev \
 x11proto-core-dev \
 wget \
 vim \
 uuid-dev \
 unzip \
 unixodbc-dev \
 unixodbc \
 unattended-upgrades \
 tightvncserver \
 # tini \
 texlive-extra-utils \
 tdsodbc \
 supervisor \
 sudo \
 software-properties-common \
 screen \
 rsync \
 rlwrap

RUN a2dismod mpm_event \
 && a2enmod macro access_compat alias auth_basic authn_core authn_file authz_core authz_host authz_user autoindex deflate dir env \
 filter headers http2 mime mpm_prefork negotiation  php7.4 proxy proxy_ajp proxy_balancer proxy_connect proxy_express \
 proxy_fcgi proxy_fdpass proxy_ftp proxy_hcheck proxy_html proxy_http proxy_http2 proxy_scgi proxy_uwsgi proxy_wstunnel reqtimeout \
 rewrite setenvif slotmem_shm socache_shmcb ssl status xml2enc ; /bin/true \
 \
# confirm our webconfig works (or it exits docker build) \
 && service apache2 start && service apache2 status && service apache2 stop

# who/where
ENV LOGICMOO_WS /opt/logicmoo_workspace
ENV LOGICMOO_USER prologmud_server
ENV LOGICMOO_GAMES $LOGICMOO_WS/prologmud_server

ENV PATH "${LOGICMOO_WS}/bin:${PATH}"
ENV WNDB $LOGICMOO_WS/packs_sys/logicmoo_nlu/data/WNprolog-3.0/prolog

MAINTAINER RUN cd $LOGICMOO_WS && set -x \
 && git checkout . \
 && git submodule update --init . \
 && cd $LOGICMOO_WS/packs_sys/logicmoo_nlu/ext/pldata && swipl -g "time(qcompile(wn_iface)),halt." \
 && cd $LOGICMOO_WS/packs_sys/logicmoo_nlu/ext/pldata && swipl -g "time(qcompile(tt0_00022_cycl)),halt." \
 \
 && cd $LOGICMOO_WS/packs_xtra/logicmoo_pldata \
 && git checkout . \
 && git checkout master \
 && cd $LOGICMOO_WS/packs_xtra/logicmoo_pldata/ext/plkb0988 \
 && swipl -g "time(qcompile(plkb0988_kb)),halt." \
 && git status \
 && git add -f plkb0988_kb.qlf \
 && cd $LOGICMOO_WS/packs_xtra/ \
 && git add -f . \
 && git commit -am "plkb0988-$(date)" \
 && cd $LOGICMOO_WS/packs_xtra/ \
 && git add logicmoo_pldata \
 && git commit -am "logicmoo_pldata-$(date)"

MAINTAINER RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && echo $SNIPPET >> "/root/.bashrc"

MAINTAINER RUN apt-get update && apt-get install -y --allow-unauthenticated \
 npm \
 && npm install -g typescript

RUN apt-get update && apt-get install -y --allow-unauthenticated \
  libtinfo5 libtinfo6

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
 && apt update \
 && apt install -g gh

RUN pip3 install junit2html



#CMD $LOGICMOO_WS/StartLogicmoo.sh
#ENTRYPOINT ["/startup_logicmoo.sh"]
ENTRYPOINT ["/startup.sh"]


