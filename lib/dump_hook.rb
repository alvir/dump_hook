require "dump_hook/version"
require "timecop"

module DumpHook
  class Settings
    attr_accessor :database,
                  :dumps_location,
                  :remove_old_dumps,
                  :actual,
                  :database_type,
                  :username,
                  :password,
                  :host,
                  :port,
                  :sources

    def initialize
      @database = 'please set database'
      @database_type = 'postgres'
      @dumps_location = 'tmp/dump_hook'
      @remove_old_dumps = true
      @sources = {}
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
    if File.exist?(filename)
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
    DumpHook.settings
  end

  def store_dump(filename)
    if settings.sources.empty?
      case settings.database_type
      when 'postgres'
        args = ['-a', '-x', '-O', '-f', filename, '-Fc', '-T', 'schema_migrations']
        args.concat(pg_connection_args)
        Kernel.system("pg_dump", *args)
      when 'mysql'
        args = mysql_connection_args
        args << "--compress"
        args.concat ["--result-file", filename]
        args.concat ["--ignore-table", "#{settings.database}.schema_migrations"]
        Kernel.system("mysqldump", *args)
      end
    else
      FileUtils.mkdir_p(filename)
      settings.sources.each do |name, parameters|
        filename_with_namespace = File.join(filename, "#{name}.dump")
        case parameters[:type]
        when :postgres
          args = ['-a', '-x', '-O', '-f', filename_with_namespace, '-Fc', '-T', 'schema_migrations']
          args.concat(['-d', parameters[:database]])
          Kernel.system("pg_dump", *args)
        when :mysql
          args = [parameters[:database], "--user", parameters[:username]]
          args << "--compress"
          args.concat(["--result-file", filename_with_namespace])
          args.concat(["--ignore-table", "#{parameters[:database]}.schema_migrations"])
          Kernel.system("mysqldump", *args)
        end
      end
    end
  end

  def restore_dump(filename)
    case settings.database_type
      when 'postgres'
        args = pg_connection_args
        args << filename
        Kernel.system("pg_restore", *args)
      when 'mysql'
        args = mysql_connection_args
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
    full_path = "#{settings.dumps_location}/#{name_with_created_on}"
    settings.sources.empty? ? "#{full_path}.dump" : full_path
  end

  def create_dirs_if_not_exists
    FileUtils.mkdir_p(settings.dumps_location)
  end

  def mysql_connection_args
    args = [settings.database]
    args.concat ['--user', settings.username] if settings.username
    args << "--password=#{settings.password}" if settings.password
    args
  end

  def pg_connection_args
    args = ['-d', settings.database]
    args.concat(['-U', settings.username]) if settings.username
    args.concat(['-h', settings.host]) if settings.host
    args.concat(['-p', settings.port]) if settings.port
    args
  end
end
