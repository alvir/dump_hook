FROM ruby:2.3-alpine
WORKDIR /gem
RUN apk add sudo build-base mariadb mariadb-dev mariadb-client postgresql postgresql-dev git && \
  mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql && \
  mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld && \
  mysql_install_db --user=mysql
USER postgres
RUN initdb /var/lib/postgresql/data && \
  pg_ctl start -D /var/lib/postgresql/data && \
  createuser -s root && \
  pg_ctl stop -D /var/lib/postgresql/data
USER root
COPY . .
RUN bundle
ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["rspec"]
