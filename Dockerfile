FROM ruby:2.3.1

ENV GIT_SSL_NO_VERIFY=true

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
