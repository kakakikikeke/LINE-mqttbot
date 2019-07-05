FROM ruby

ADD . /home
WORKDIR /home
RUN gem install bundler
RUN bundle install --path vendor

CMD bundle exec rackup config.ru -o 0.0.0.0 -p $PORT