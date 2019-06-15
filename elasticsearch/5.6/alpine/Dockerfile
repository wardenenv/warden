FROM elasticsearch:5.6-alpine

RUN apk add --no-cache bash \
    && bin/elasticsearch-plugin install analysis-phonetic \
    && echo "export PS1='\[\033[0;0m\]\u@\h\[\033[0m\]:\[\033[0;31m\]\w\[\033[0m\]# '" >> /root/.bashrc
