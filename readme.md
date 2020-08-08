# Test task DE Profitero

## Getting Started

### Requirements

You must have latest `Ruby` installed on your OS (at least `ruby 2.7.0p0 (2019-12-25 revision 647ee6f091)`)
Follow [this](https://www.ruby-lang.org/en/documentation/installation/) page to install Ruby on your OS

You must have `libcurl` installed on your OS
Use sudo `apt-get install libcurl4-openssl-dev` or `sudo apt-get install libcurl4-gnutls-dev` to install it on Linux
Or just download from [here](https://curl.haxx.se/download.html) to install it on Windows

### Dependencies
`nokogiri`,
`thread`,
`concurrent-ruby`,
`curb`,
`pry`

### Installing

#### You have to install bundler first
##### `gem install bundler`
#### Run `bundler install` to prepare gems

### Run
Use `ruby main.rb` to run

### Run examples
* `ruby main.rb --u=https://www.petsonic.com/snacks-huesos-para-perros/ --o=out`
* `ruby main.rb --u=https://www.petsonic.com/snacks-huesos-para-perros/ --o=out.csv` - same as previous
* `ruby main.rb --u=https://www.petsonic.com/snacks-huesos-para-perros/?categorias=barritas-para-perros --o=out`
* `ruby main.rb --u=https://www.petsonic.com/snacks-huesos-para-perros/ --c=?categorias=barritas-para-perros --o=out`  - same as previous
* `ruby main.rb --u=https://www.petsonic.com/tienda-perros/ --o=out` - so long request
* `ruby main.rb` - to run with debug params (90 products)

* `ruby main.rb -h` or `ruby main.rb -help` - help

Original repository: [HelloRuby](https://github.com/DangouHaim/HelloRuby)