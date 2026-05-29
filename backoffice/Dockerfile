FROM ruby:3.2-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      curl \
      pkg-config \
      libpq-dev \
      libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
