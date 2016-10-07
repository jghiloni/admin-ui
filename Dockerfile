FROM ruby:2.3.1

ARG ccdb_user
ARG ccdb_password
ARG ccdb_host_port

ARG cf_system_domain

ARG admin_ui_client
ARG admin_ui_secret

ARG uaadb_user
ARG uaadb_password
ARG uaadb_host_port

ARG http_proxy
ARG https_proxy

ARG GIT_SSL_NO_VERIFY

RUN apt-get update
RUN apt-get install -f -y --no-install-recommends \
   git-core build-essential libreadline-dev libssl-dev \
   libsqlite3-dev openssl libpq-dev libmysqlclient-dev \
   gettext

RUN git clone https://github.com/jghiloni/admin-ui.git

WORKDIR admin-ui
RUN bundle install

RUN envsubst < config/default.tmpl > config/default.yml

ENTRYPOINT ruby bin/admin

EXPOSE 8070:8070
