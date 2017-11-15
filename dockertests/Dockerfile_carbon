FROM node:carbon
MAINTAINER M. Peter <mp@tcs.de>

RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y build-essential

RUN	mkdir -p /usr/src/
WORKDIR /usr/src/

COPY package.json /usr/src/package.json

RUN npm install --production
RUN npm install mocha should

COPY lib/ /usr/src/lib/
COPY test/ /usr/src/test/
COPY index.js /usr/src/

CMD [ "npm", "run", "test-docker" ]
