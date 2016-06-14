# Dumper

Библиотека, которая позволяет закэшировать состояние базы по выполнению 
каких-либо действий. Мы используем это в тестах для оптимизации накликивания 
больших и малых объёмов данных. Помните, что создание дампа призвано лишь оптимизировать
прохождение тестов, которые созданы с помощью прокликивания и всё, что вы напишите 
внутри блока, может быть использовано против вас. Также надо помнить, что кэшируется 
лишь база(ведь мы хотели убрать создание строчек в базе), это предпологает, что
остальные изменения окружающей среды(куки, сессии, файлы) не будут сохранены, и 
должны быть в том же положении, что и до дампа.

## Installation

```ruby
gem 'dumper'
```

## Configuration

В Cucumber:
```ruby
Dumper.setup do |config|
  config.database = ActiveRecord::Base.configurations[Rails.env]['database']
  config.actual = Date.today.monday.to_s(:number)
end

World(Dumper)
```

Есть ещё параметр `config.dumps_location`, который по умолчанию `tmp/dumper`. Вы 
можете выставить другое значение, если хотите, например, что ваши бампы попадали
в репозиторий. Значение `config.actual` это признак актуальности, которое постоянно
пока дамп актуален, в случае его изменения будет создан новый дамп, по умолчанию 
`nil`. Значение database на данный момент это имя базы. Скорее всего буду проблемы 
с правами пользователя в базе и надо будет улучшить настройки на то, чтоб их 
тоже можно было передать.

Теперь когда настройки заданы, можно перейти к использованию.

## Usage

*Внимание!* Всё это работает только если база перед созданием дампа чистая и не 
вызывает конфликтов вставки данных. У нас подобные проблемы периодически случаются.

Так как есть только один основной метод
```ruby
execute_with_dump(name, opts={}, &block)
```
который помимо имени в первом параметре принимает ещё хэш опций. Опции могут 
быть такие `:created_on`, которая переведёт стрелки для действий в блоке. Ещё одна
опция `:actual`, которая такая же как глобальная actual, только для конкретного 
случая.

Мы пока обременены Cucumber-ом, поэтому примеры такие.

Шаг обертка для дампа (может, нужно её добавить в гем)
```ruby
Given(/^There is "(.*?)" background with:$/) do |name, steps|
  execute_with_dump(name) do
    steps.split(/\n+/).each do |step_definition|
      step step_definition.strip
    end
  end
end
```

Использование шага
```cucumber
Feature: Tags can be deleted and modified
  Background:
    Given There is "tags" background with:
    """
    There is admin with login "admin"
    I login as user with login "admin"
    Customer "Rick Roe" with email "rick@mailinator.com" has invoiceable project "The Andromeda"

    There is employee "Bred"
    "Bred" is member in the project "The Andromeda"

    I am on the project "The Andromeda" stories planning page

    Project has tags "one, two, three, four, cool"

    Project "The Andromeda" has story "[#three #four #cool] Create design" with description "Create design description" and estimate "10"

    User "Bred" login through email link
    I logout
    """
     And I login as user with login "bred"
     And I am on the project "The Andromeda" tags page

  Scenario: I should see all project's tags
    Then I should see all project tags "one, two, three, four, cool"

  Scenario: Delete tag
    When I delete tag "one"
    Then I should be stay on the project "The Andromeda" tags page
     And I should not see "one"

  Scenario: Create tag
    When I fill in "test" for "New tag:"
     And I press "Create"
    Then I should see "test"
```

Создание состояния
```ruby
module ProjectData
  def create_project_data(timestamp=nil)
    execute_with_dump('project_data', created_on: timestamp) do
      create_superadmin
      login_as('admin')

      create_projects
    
      # другие действия по заполнению данных касающихся проектов

      logout
  end
end  
```

Шаг обертка для состояния
```ruby
Given(/^There is Project environment(?: on "(.*?)")?$/) do |timestamp|
  if timestamp
    create_project_data(Time.parse(timestamp))
  else
    create_project_data
  end
end
```

Использование шага для состояния

```cucumber
@javascript
Feature: Drag and drop feature

  Background:
    Given There is Project environment
      And I login as user with login "jd"
      And I am on the project "Evolution" stories planning page
      And I should see "Game cards" in the current period group

  Scenario: drag and drop story between two periods
     When I drag the "Game cards" from the current period group to the next period group
     Then I should see "Game cards" in the next period group

  Scenario: drag and drop story to unscheduled
     When I drag the "Game cards" from the current period group to the unscheduled group
     Then I should see "Game cards" in the unscheduled group

  Scenario: drag and drop story to Overdue group
     When I drag the "Game cards" from the current period group to the overdue group
     Then I should see "Game cards" in the current period group
```

К сожалению, пока нет примеров без Cucumber, но есть ощущение, что всё должно быть неплохо и без него.

## Что надо сделать

* Удаление старых ненужных дампов
* Поддержка других баз
* Кэширование файлов и сессий(может в другой библиотечке)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
