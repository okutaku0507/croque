# Croque

Croque is a simple aggregator of log. It will be useful for notifications of slow request.

By the way,  **Croque** Monsieur is a baked or fried boiled ham and cheese sandwich. The dish originated in French cafés and bars as a quick snack.

<img src="https://user-images.githubusercontent.com/4189626/31853769-560ed0b6-b6c9-11e7-8166-8351a0eecc8e.jpg" width="200px">

## Installation

This gem is developed as a plugin for rails gem.

Add this line to your application's Gemfile:

```ruby
gem 'croque'
```

## Configuration

Croque's default configurations.

```ruby
Croque.configure do |config|
  config.root_path = Pathname.new(Rails.root || Dir.pwd)
  config.log_dir_path = config.root_path.join('log')
  config.store_path = config.root_path.join('tmp', 'croque', Rails.env)
  config.log_file_matcher = /#{Rails.env}.log/
  config.hour_matcher = /dateThour/
  config.severity_matcher = /severity/
  config.matcher = /\[#{config.hour_matcher.source}:\d{2}:\d{2}\.\d+ #{config.severity_matcher.source}\]/
  config.start_matcher = /\-\- : Started/
  config.end_matcher = /\-\- : Completed/
  config.lower_time = 1000 # ms
  config.except_path_matcher = /\/assets\//
  config.logger = Logger.new(config.log_dir_path.join("croque.#{Rails.env}.log"))
end
```

## Usage

Croque treats the date as a unit.

First, do aggregate.

```ruby
Croque.aggregate(Date.yesterday)
```

Then, csv files will be output to the directory pointed  by store_path.

Next, get ranking as Array.

```ruby
ranking_list = Croque.ranking(Date.yesterday)
=> [
  #<Croque::Monsieur:0x00007fd727979ce8 @date=Sat, 21 Oct 2017, @hour=12, @id="3441444b-a6d4-460f-a37d-821e699d7a63", @time="1200.0">,
  #<Croque::Monsieur:0x00007fd727929400 @date=Sat, 21 Oct 2017, @hour=8, @id="becb857d-31f2-47ee-9029-e034e07c7f06", @time="812.0">,
  #<Croque::Monsieur:0x00007fd727929400 @date=Sat, 21 Oct 2017, @hour=23, @id="c29c7e0d-a56d-468e-8ab0-636e09b44996", @time="564.0">
]

# monsieur is a ranking object
monsieur = ranking_list[0]
=> #<Croque::Monsieur:0x00007fd727979ce8 @date=Sat, 21 Oct 2017, @hour=12, @id="3441444b-a6d4-460f-a37d-821e699d7a63", @time="1200.0">

monsieur.body
I, [2017-10-21T12:55:04.566846 #22212]  INFO -- : Started GET "/demo?tomato=delicious&kyouha=hare" for 127.0.0.1 at 2017-10-21 12:55:30 +0900
I, [2017-10-21T12:53:06.566846 #22212]  INFO -- : Processing by Rails::WelcomeController#index as HTML
I, [2017-10-21T12:53:10.807962 #22212]  INFO -- : Completed 200 OK in 1200ms (Views: 199.9ms | ActiveRecord: 1000.1ms)
=> [
  "I, [2017-10-21T12:55:04.566846 #22212]  INFO -- : Started GET \"/demo?tomato=delicious&kyouha=hare\" for 127.0.0.1 at 2017-10-21 12:55:30 +0900",
  "I, [2017-10-21T12:53:06.566846 #22212]  INFO -- : Processing by Rails::WelcomeController#index as HTML",
  "I, [2017-10-21T12:53:10.807962 #22212]  INFO -- : Completed 200 OK in 1200ms (Views: 199.9ms | ActiveRecord: 1000.1ms)"
]

monsieur.views_time
=> 199.9 # ms

monsieur.active_record_time
=> 1000.1 # ms

monsieur.processing_time
=> 1200.0 # ms

monsieur.full_path
=> "/demo?tomato=delicious&kyouha=hare"

monsieur.path_info
=> "/demo"

monsieur.query
=> "tomato=delicious&kyouha=hare"
```

paginate

```ruby
Croque.ranking(Date.yesterday. page: 1, per: 50)
```

all dates whose the ranking exist

```ruby
Croque.all
=> [Sat, 21 Oct 2017]
```

total count of the ranking

```ruby
Croque.total_count(Date.yesterday)
=> 1
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/croque. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Copyright
Copyright (c) 2017 Takuya Okuhara. Licensed under the  [MIT License](http://opensource.org/licenses/MIT).
