FROM node:23.7.0-alpine
WORKDIR /usr/app
COPY package.json yarn.lock ./
RUN yarn
COPY . .
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN yarn build

FROM nginx:stable-alpine
COPY --from=0 /usr/app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]