Setup on Ubuntu 14.04 LTS
-------------------------------------

### Overview

1. Setup deploy user
2. Install [Ruby](https://www.ruby-lang.org/en/)
3. Install [MySQL](http://www.mysql.com/)
4. Install [Redis](http://redis.io/)
5. Install [RabbitMQ](https://www.rabbitmq.com/)
6. Install [Bitcoind](https://en.bitcoin.it/wiki/Bitcoind)
7. Install [PhantomJS](http://phantomjs.org/)
7. Configure Peatio

### 1. Setup deploy user

Create (if it doesn’t exist) deploy user, and assign it to the sudo group:

    adduser deploy
    usermod -a -G sudo deploy

Re-login as deploy user

### 2. Install Ruby

Make sure your system is up-to-date.

    sudo apt-get update
    sudo apt-get upgrade

Installing [rbenv](https://github.com/sstephenson/rbenv) using a Installer

    sudo apt-get install git-core curl zlib1g-dev build-essential \
                         libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
                         libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties

    cd
    git clone git://github.com/sstephenson/rbenv.git .rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    exec $SHELL

    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    exec $SHELL

Install Ruby 2.1.2 through rbenv:

    rbenv install 2.1.2
    rbenv global 2.1.2

Install bundler

    echo "gem: --no-ri --no-rdoc" > ~/.gemrc
    gem install bundler
    rbenv rehash

### 3. Install MySQL

    sudo apt-get install mysql-server  mysql-client  libmysqlclient-dev

### 4. Install Redis

Be sure to install the latest stable Redis, as the package in the distro may be a bit old:

    sudo apt-add-repository -y ppa:rwky/redis
    sudo apt-get update
    sudo apt-get install redis-server

### 5. Install RabbitMQ

Please follow instructions here: https://www.rabbitmq.com/install-debian.html

    sudo apt-add-repository 'deb http://www.rabbitmq.com/debian/ testing main'
    curl http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install rabbitmq-server

    sudo rabbitmq-plugins enable rabbitmq_management
    sudo service rabbitmq-server restart
    wget http://localhost:15672/cli/rabbitmqadmin
    chmod +x rabbitmqadmin
    sudo mv rabbitmqadmin /usr/local/sbin

### 6. Install Bitcoind

    sudo add-apt-repository ppa:bitcoin/bitcoin
    sudo apt-get update
    sudo apt-get install bitcoind

**Configure**

    mkdir -p ~/.bitcoin
    touch ~/.bitcoin/bitcoin.conf
    vim ~/.bitcoin/bitcoin.conf

Insert the following lines into the bitcoin.conf, and replce with your username and password.

    server=1
    daemon=1
    rpcuser=INVENT_A_UNIQUE_USERNAME
    rpcpassword=INVENT_A_UNIQUE_PASSWORD

    # If run on the test network instead of the real bitcoin network
    testnet=1

    # Notify when receiving coins
    walletnotify=/usr/local/sbin/rabbitmqadmin publish routing_key=peatio.deposit.coin payload='{"txid":"%s", "channel_key":"satoshi"}'

**Start bitcoin**

    bitcoind

### 7. Install PhantomJS

Peatio uses Capybara with PhantomJS to do the feature tests, so if you want to run the tests. Install the PhantomJS is neccessary.

    sudo apt-get update
    sudo apt-get install build-essential chrpath git-core libssl-dev libfontconfig1-dev
    git clone git://github.com/ariya/phantomjs.git
    cd phantomjs
    git checkout 1.9
    ./build.sh

### 8. Configure Peatio

**Clone the project**

    git clone git://github.com/peatio/peatio.git
    cd peatio
    bundle install

**Prepare configure files**

    bin/init_config

**Setup reCAPTCHA / Pusher**

* Peatio use [reCAPTCHA](https://www.google.com/recaptcha) to make sure certain operations is not done by bots. A development key/secrect pair is provided in `config/application.yml` (uncomment to use). PLEASE USE IT IN DEVELOPMENT/TEST ENVIRONMENT ONLY!
* Peatio depends on [Pusher](http://pusher.com). A development key/secret pair for development/test is provided in `config/application.yml` (uncomment to use). PLEASE USE IT IN DEVELOPMENT/TEST ENVIRONMENT ONLY!

More details to visit [pusher official website](http://pusher.com)

    # uncomment reCAPTCHA and Pusher related settings
    vim config/application.yml

**Setup bitcoind rpc endpoint**

    # replace username:password and port with the one you set in
    # username and password should only contain letters and numbers, do not use email as username
    # bitcoin.conf in previous step
    vim config/currencies.yml

**Config database settings**

    vim config/database.yml

    # Initialize the database and load the seed data
    bundle exec rake db:setup

**Run Daemons**

    # start all daemons
    bundle exec rake daemons:start

    # or start daemon one by one
    bundle exec rake daemon:matching:start
    ...

    # Daemon trade_executor can be run concurrently, e.g. below
    # line will start four trade executors, each with its own logfile.
    # Default to 1.
    TRADE_EXECUTOR=4 rake daemon:trade_executor:start

    # You can do the same when you start all daemons:
    TRADE_EXECUTOR=4 rake daemon:start

**Run Peatio**

    # start server
    bundle exec rails server

**Visit [http://localhost:3000](http://localhost:3000)**

    user: admin@peatio.dev
    pass: Pass@word8
