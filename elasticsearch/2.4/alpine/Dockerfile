FROM elasticsearch:2.4-alpine

RUN apk add --no-cache bash \
    && bin/plugin install analysis-phonetic \
    && echo "export PS1='\[\033[0;0m\]\u@\h\[\033[0m\]:\[\033[0;31m\]\w\[\033[0m\]# '" >> /root/.bashrc
