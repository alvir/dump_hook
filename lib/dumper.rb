require "dumper/version"

module Dumper
  mattr_accessor(:database) { "please_configure_database" }

  def self.setup
    yield(self)
  end

  def execute_with_dump(name, opts={}, &block)
    created_on = opts[:created_on]
    create_dirs_if_not_exists
    filename = full_filename(name, created_on)
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

  def full_filename(name, created_on)
    name_with_created_on = name
    if created_on
      name_with_created_on << "_#{created_on.to_s(:number)}"
    end
    "#{dumps_location}/#{name_with_created_on}.dump"
  end

  def dumps_location
    "tmp/dumper"
  end

  def create_dirs_if_not_exists
    unless Dir.exists?("tmp")
      Dir.mkdir("tmp")
    end
    unless Dir.exists?(dumps_location)
      Dir.mkdir(dumps_location)
    end
  end
end
