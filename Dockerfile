FROM ruby:3.4.4-alpine3.21

ADD . /home
WORKDIR /home

RUN apk add build-base libffi-dev

RUN gem install bundler
RUN bundle config path vendor
RUN bundle install

CMD bundle exec rackup config.ru -o 0.0.0.0 -p $PORT
