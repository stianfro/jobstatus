FROM ruby:2.7.6

WORKDIR /usr/src/jobstatus

RUN gem install httparty sinatra thin

COPY . .

CMD ["./app/jobstatus.rb"]
