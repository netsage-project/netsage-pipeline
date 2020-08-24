FROM ruby:2.6.6

RUN mkdir /home/app
COPY . /home/app
WORKDIR /home/app

RUN gem install bundler && \
    bundle install
#RUN apt-get update -qq && apt-get install -y nodejs

ENTRYPOINT [ "/bin/bash" ]