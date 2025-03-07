FROM node:23.7.0-alpine
WORKDIR /usr/app
COPY package.json yarn.lock ./
RUN yarn
COPY . .
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN yarn build
EXPOSE 3000
CMD ["npx", "serve", "-s", "build"] 