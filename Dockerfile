FROM docker.io/library/alpine

ARG D=/cacerts

RUN apk add --update openssl nodejs npm

RUN adduser -G root -D -u 1001 appuser

RUN mkdir -p /app \
 && mkdir -p ${D}/rootCA/certs \
 && mkdir -p ${D}/rootCA/crl \
 && mkdir -p ${D}/rootCA/newcerts \
 && mkdir -p ${D}/rootCA/private \
 && mkdir -p ${D}/rootCA/csr \
 && mkdir -p ${D}/rootCA/passw \
 && mkdir -p ${D}/intermediateCA/certs \
 && mkdir -p ${D}/intermediateCA/crl \
 && mkdir -p ${D}/intermediateCA/newcerts \
 && mkdir -p ${D}/intermediateCA/private \
 && mkdir -p ${D}/intermediateCA/csr \
 && mkdir -p ${D}/intermediateCA/passw \
 && echo 'F001000' > ${D}/rootCA/serial \
 && echo 'F002000' > ${D}/intermediateCA/serial \
 && echo 'F003000' > ${D}/rootCA/crlnumber \ 
 && echo 'F004000' > ${D}/intermediateCA/crlnumber \
 && touch ${D}/rootCA/index.txt \ 
 && touch ${D}/intermediateCA/index.txt \
 && chown -R 1001:0 /app \
 && chown -R 1001:00 /cacerts

USER 1001

COPY --chown=1001:0 ./openssl_root.cnf /cacerts

COPY --chown=1001:0 ./openssl_intermediate.cnf /cacerts
