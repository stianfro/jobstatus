FROM ruby:2.6

WORKDIR /usr/src/jobstatus

RUN gem install httparty sinatra thin

COPY . .

CMD ["./app/jobstatus.rb"]
