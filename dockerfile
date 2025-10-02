FROM node:22-alpine

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN npm i -g pnpm prisma && pnpm install

COPY ./src ./src
COPY ./prisma ./prisma

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN dos2unix /usr/local/bin/entrypoint.sh || sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /mitm
COPY catalyst-mitm/EA-MITM.ini /mitm/
COPY catalyst-mitm/dinput8.dll /mitm/

EXPOSE 3000 25565 42230

CMD ["/usr/local/bin/entrypoint.sh"]