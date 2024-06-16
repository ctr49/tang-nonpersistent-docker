FROM debian:bookworm-slim
RUN apt-get update && apt-get -y install --no-install-recommends tang socat nginx-light
RUN adduser --disabled-password --gecos "" myuser
RUN mkdir -p /var/db/tang /run/nginx && chown -R myuser:myuser /var/db/tang /run/nginx /var/lib/nginx
ADD --chown=myuser:myuser . /home/
RUN chmod 755 /home/myuser/start.sh

USER myuser
CMD ["/home/myuser/start.sh"]
