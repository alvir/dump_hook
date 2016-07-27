require "dumper/version"
require "timecop"

module Dumper
  class Settings
    attr_accessor :database, :dumps_location, :remove_old_dumps, :actual, :database_type, :username

    def initialize
      @database = 'please set database'
      @database_type = 'postgres'
      @dumps_location = 'tmp/dumper'
      @remove_old_dumps = true
    end
  end

  class << self
    attr_accessor :settings
  end

  def self.setup
    self.settings = Settings.new
    yield(settings)
  end

  def execute_with_dump(name, opts={}, &block)
    created_on = opts[:created_on]
    actual = opts[:actual] || settings.actual
    create_dirs_if_not_exists
    filename = full_filename(name, created_on, actual)
    if File.exists?(filename)
      restore_dump(filename)
    else
      if created_on
        Timecop.travel(created_on)
      elsif actual && settings.remove_old_dumps
        FileUtils.rm(Dir.glob(full_filename(name, nil, "*")))
      end
      block.call
      Timecop.return
      store_dump(filename)
    end
  end

  def settings
    Dumper.settings
  end

  def store_dump(filename)
    case settings.database_type
      when 'postgres'
        args = ['-a', '-x', '-O', '-f', filename, '-Fc', '-T', 'schema_migrations']
        args << settings.database
        Kernel.system("pg_dump", *args)
      when 'mysql'
        args = ["--compress"]
        args.concat ['--user', settings.username]
        args.concat ["--result-file", filename]
        args.concat ["--ignore-table", "#{settings.database}.schema_migrations"]
        args.concat ["--databases", settings.database]
        Kernel.system("mysqldump", *args)
    end
  end

  def restore_dump(filename)
    case settings.database_type
      when 'postgres'
        args = ['-d', settings.database, filename]
        Kernel.system("pg_restore", *args)
      when 'mysql'
        args = [settings.database]
        args.concat ['--user', settings.username]
        args.concat ["-e", "source #{filename}"]
        Kernel.system("mysql", *args)
    end
  end

  def full_filename(name, created_on, actual)
    name_with_created_on = name
    if created_on
      name_with_created_on = "#{name_with_created_on}_#{created_on.to_s(:number)}"
    elsif actual
      name_with_created_on = "#{name_with_created_on}_actual#{actual}"
    end
    "#{settings.dumps_location}/#{name_with_created_on}.dump"
  end

  def create_dirs_if_not_exists
    FileUtils.mkdir_p(settings.dumps_location)
  end
end
