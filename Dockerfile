FROM ubuntu:22.04
RUN apt-get update && apt-get -y install --no-install-recommends tang socat nginx-light
RUN adduser --disabled-password --gecos "" myuser
RUN mkdir -p /var/db/tang /run/nginx && chown -R myuser.myuser /var/db/tang /run/nginx /var/lib/nginx
ADD --chown=myuser:myuser . /home/
RUN chmod 755 /home/myuser/start.sh
RUN rm -f /etc/nginx/sites-enabled/default
RUN ln -s /home/myuser/nginx-reverse-tang /etc/nginx/sites-enabled/reverse-tang
RUN sed -i "s|/run/nginx.pid|/run/nginx/nginx.pid|" /etc/nginx/nginx.conf
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log

USER myuser
CMD ["/home/myuser/start.sh"]
