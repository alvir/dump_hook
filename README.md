# Dump Hook

A library, what helps to cache your data by performing some user actions. We use in our acceptance tests to enhance 
performance of use clicks and actions of preparing data for the tests. Now we cache just Postgres and MySql db and 
you need to take care about other sources your own.  

## Installation

```ruby
gem 'dump-hook'
```

For Rspec/Capybara add to `rails_helper.rb`:
```ruby
require "dump_hook"

RSpec.configure do |config|
  config.include DumpHook
end
```

For Cucumber/Capybara add to `env.rb`:
```ruby
require "dump_hook"

World(DumpHook)
```

## Configuration

There are several parameters to make it run and manage.

```ruby
DumpHook.setup do |config|
  config.database = ActiveRecord::Base.configurations[Rails.env]["database"]
  config.actual = Date.today.monday.to_s(:number)
end
```

### Db settings:
* `database` - database name
* `host` - DB server
* `port` - DB server port
* `username` - user to connect
* `password` - password to connect, works just for MySql
* `database_type` - `postgres`/`mysql`, by default it's `postgres`

It looks like `database` is a single required parameter. Others may be default for you DB connection. In relation to 
`password` for `postgres` you need to use the url way in `database` parameter in order to set `password`. You may use 
the gem `database_url` to get this url.

```ruby
config.database = postgresql://username:password@localhost/database
```
### Dump hook settings
* `actual` - an attribute to manage how long or when you need to create a new dump for your actions. For instance, you 
may set it to `Date.current` to recreate your dumps every day. By default it's empty and your dumps will not recreate.
* `remove_old_dumps` - when `actual` is pointed your old dumps will be removed. By default it's `true`.
* `dumps_location` - by default it's `tmp/dump_hook`. You may pass something more exciting, e.g your current git branch
or some path to store your dumps in your repo and generate them using CI.

## Usage

*Attention!* It works for clear DB. In case when you have some previous data you may come across with conflicts or 
incorrect data which may influence your tests.  

There is just single method what wrap your actions and restore dump again
```ruby
execute_with_dump(name, opts={}, &block)
```
* `name` - identity what explain meaning of this background
* `opts[:actual]` - the same to the global parameter `actual` what override it
* `opts[:created_on]` - Date time to use in Time travelling for time dependent tests. In this case `actual` is 
unnecessary and ignored. If you want to recreate such dumps you need to clean them manually.  

### Capybara example
```ruby
execute_with_dump("user_data") do
  create_superadmin
  login_as_superadmin
  go_to_users
  add_user("John Doe")
  add_user("Adam Smith")
  add_user("Robert Martin")
  add_user("Kent Beck")
  logout
end

```
### Cucumber example

You can use the capybara way or create a wrap step to have all actions in your features
```ruby
Given(/^There is "(.*?)" background with:$/) do |name, steps_order|
  execute_with_dump(name) do
    steps steps_order.to_s
  end
end
```

and use it in your scenarios
```cucumber
Feature: User can modify project
  Background:
    Given There is "project_modification" background with:
    """
    There is the user data
    I login as superadmin
    I create a project "Time tracking"
    I logout
    """

  Scenario: I can rename project
    Given I login as "John Doe"
      And I go to the projects
      And I click "Edit" for "Time tracking" project
     When I fill out "name" with "Time management"
      And I click "Save"
     Then I see the notification "Project is updated"  
```

In this example `There is the user data` is step what wraps the capybara example

## How to add new sources or hooks
_Disclaimer_: We understand the current way is not pretty good and work on enhancements

If you need to add yet one source, e.g we have yet one service and need to dump its data you may use something similar
```ruby
module YourServiceHook
  def store_dump(filename)
    super
    data = YourServiceAPI.import
    File.open(your_service_filename(filename), "w") do |f| 
      f.write(data)
    end
  end

  def restore_dump(filename)
    super
    buffer = File.open(your_service_filename(filename)).read
    YourServiceAPI.export(buffer)
  end
  
  def your_service_filename
    filename.gsub(".dump", ".your_service")
  end
end
```

## TODO

* Dump other sources like `cookies`, Elastic Search, etc. 
* Enhance ways of adding hooks to extend current sources without overriding(In progress)
* Add some sugar to create common dumps for CI or `parallel_tests`


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
