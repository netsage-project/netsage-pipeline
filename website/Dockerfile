FROM node:12.19.0

WORKDIR /app

EXPOSE 3000 35729
COPY . /app
RUN yarn install

CMD ["yarn", "start"]