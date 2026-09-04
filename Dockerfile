FROM ruby:4.0.5-alpine3.23

WORKDIR /home

RUN apk add build-base libffi-dev yaml-dev

ADD . /home

RUN gem install bundler
RUN bundle config path vendor
RUN bundle install

RUN addgroup -S mqttbot && adduser -S mqttbot -G mqttbot \
        && chown -R mqttbot:mqttbot /home
USER mqttbot

CMD bundle exec rackup config.ru -o 0.0.0.0 -p $PORT
