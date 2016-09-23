FROM debian:wheezy-backports

ARG TERM=linux
ARG DEBIAN_FRONTEND=noninteractive

# restyaboard version
ENV restyaboard_version=v0.2.1
ENV restyaboard_repo=stepanorda/board

# update & install package
RUN apt-get update --yes
RUN apt-get install --yes zip curl cron postgresql nginx
RUN apt-get install --yes php5 php5-fpm php5-curl php5-pgsql php5-imagick libapache2-mod-php5
RUN echo "postfix postfix/mailname string example.com" | debconf-set-selections \
        && echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections \
        && apt-get install -y postfix

# deploy app
#RUN curl -L -o /tmp/restyaboard.zip https://github.com/RestyaPlatform/board/releases/download/${restyaboard_version}/board-${restyaboard_version}.zip \
#        && unzip /tmp/restyaboard.zip -d /usr/share/nginx/html \
#        && rm /tmp/restyaboard.zip

# additional packages neaded to build
RUN apt-get install git npm && ln -s /usr/bin/nodejs /usr/bin/node \
        && npm install grunt grunt-template-jasmine-istanbul grunt-contrib-jshint grunt-phplint grunt-contrib-less grunt-contrib-jst grunt-contrib-concat grunt-jsbeautifier grunt-prettify grunt-contrib-cssmin grunt-contrib-uglify grunt-filerev grunt-usemin grunt-contrib-htmlmin grunt-exec grunt-lineending grunt-regex-replace grunt-manifest grunt-zip grunt-contrib-jasmine grunt-plato grunt-complexity grunt-docco grunt-contrib-watch

# deploy app from git
RUN cd /usr/share/nginx/html && git clone https://github.com/${restyaboard_repo}.git . \
        && grunt less && grunt jst

# setting app
WORKDIR /usr/share/nginx/html
RUN cp -R media /tmp/ \
        && cp restyaboard.conf /etc/nginx/conf.d \
        && sed -i 's/^.*listen.mode = 0660$/listen.mode = 0660/' /etc/php5/fpm/pool.d/www.conf \
        && sed -i 's|^.*fastcgi_pass.*$|fastcgi_pass unix:/var/run/php5-fpm.sock;|' /etc/nginx/conf.d/restyaboard.conf \
        && sed -i -e "/fastcgi_pass/a fastcgi_param HTTPS 'off';" /etc/nginx/conf.d/restyaboard.conf

# volume
VOLUME /usr/share/nginx/html/media

# entry point
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]

# expose port
EXPOSE 80
