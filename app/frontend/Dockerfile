FROM node:20-alpine
WORKDIR /app
RUN npm init -y && npm i express
COPY index.js .
EXPOSE 8080
CMD ["node","index.js"]
