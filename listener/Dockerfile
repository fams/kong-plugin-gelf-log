FROM node:lts
LABEL mantainer=fams@linuxplace.com.br
WORKDIR  /srv/listener
COPY ./package.json ./
COPY ./server.js ./

RUN npm install
EXPOSE 12201/udp
CMD ["node", "server.js"]
