FROM coreos/openresty
ENV PATH /usr/local/openresty/nginx/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 8080
ADD nginx.conf /app/conf/nginx.conf
ADD lib /app/lib
CMD nginx -p /app/ -c conf/nginx.conf
