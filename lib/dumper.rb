require "dumper/version"

module Dumper
  mattr_accessor(:database) { "please_configure_database" }
  mattr_accessor(:dumps_location) { "tmp/dumper" }
  mattr_accessor(:actual)

  def self.setup
    yield(self)
  end

  def execute_with_dump(name, opts={}, &block)
    created_on = opts[:created_on]
    actual = opts[:actual] || self.actual
    create_dirs_if_not_exists
    filename = full_filename(name, created_on, actual)
    if File.exists?(filename)
      restore_dump(filename)
    else
      if created_on
        Timecop.travel(created_on)
      end
      block.call
      Timecop.return
      store_dump(filename)
    end
  end

  def store_dump(filename)
    args = ['-a', '-x', '-O', '-f', filename, '-Fc', '-T', 'schema_migrations']
    args << database
    Kernel.system("pg_dump", *args)
  end

  def restore_dump(filename)
    args = ['-d', database, filename]
    Kernel.system("pg_restore", *args)
  end

  def full_filename(name, created_on, actual)
    name_with_created_on = name
    if created_on
      name_with_created_on = "#{name_with_created_on}_#{created_on.to_s(:number)}"
    elsif actual
      name_with_created_on = "#{name_with_created_on}_actual#{actual}"
    end
    "#{dumps_location}/#{name_with_created_on}.dump"
  end

  def create_dirs_if_not_exists
    FileUtils.mkdir_p(dumps_location)
  end
end
