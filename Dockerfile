FROM ruby:3.1.2

ADD . /home
WORKDIR /home
RUN gem install bundler
RUN bundle config path vendor
RUN bundle install

CMD bundle exec rackup config.ru -o 0.0.0.0 -p $PORT
