FROM erdii/nodejs-alpine-buildtools:6.0.0
MAINTAINER M. Peter <mp@tcs.de>

RUN	mkdir -p /usr/src/
WORKDIR /usr/src/

COPY package.json /usr/src/package.json

RUN npm install --production
RUN npm install mocha should

COPY lib/ /usr/src/lib/
COPY test/ /usr/src/test/
COPY index.js /usr/src/

CMD [ "npm", "run", "test-docker" ]
