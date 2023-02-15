FROM ruby:3.1.3-slim

WORKDIR /usr/src/jobstatus

RUN gem install httparty sinatra thin

COPY . .

CMD ["./app/jobstatus.rb"]
