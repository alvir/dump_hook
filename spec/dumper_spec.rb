require 'spec_helper'
require 'sequel'

describe Dumper do
  it 'has a version number' do
    expect(Dumper::VERSION).not_to be nil
  end

  describe '.setup' do
    context 'default settings' do
      before(:each) do
        Dumper.setup do |_|
        end
      end

      it 'sets dumps_location' do
        expect(Dumper.settings.dumps_location).to eq('tmp/dumper')
      end

      it 'sets remove_old_dumps' do
        expect(Dumper.settings.remove_old_dumps).to eq(true)
      end

      it 'sets database' do
        expect(Dumper.settings.database).to eq('please set database')
      end

      it 'does not set actual' do
        expect(Dumper.settings.actual).to be nil
      end
    end

    context 'custom settings' do
      let(:new_location) { 'new_location' }
      let(:new_remove_old_dumps) { false }
      let(:new_database) { 'new_database' }
      let(:new_actual) { 'actual_with_some_phrase' }

      it 'sets dumps_location' do
        Dumper.setup { |c| c.dumps_location = new_location }
        expect(Dumper.settings.dumps_location).to eq(new_location)
      end

      it 'sets remove_old_dumps' do
        Dumper.setup { |c| c.remove_old_dumps = new_remove_old_dumps }
        expect(Dumper.settings.remove_old_dumps).to eq(new_remove_old_dumps)
      end

      it 'sets database' do
        Dumper.setup { |c| c.database = new_database }
        expect(Dumper.settings.database).to eq(new_database)
      end

      it 'sets actual' do
        Dumper.setup { |c| c.actual = new_actual }
        expect(Dumper.settings.actual).to eq(new_actual)
      end
    end
  end

  describe '.execute_with_dump' do
    let(:object) { object = Object.new }

    before(:each) do
      object.extend(Dumper)
    end

    context 'folders creation' do
      let(:dumps_location) { "tmp1/tmp2/tmp3" }

      before(:each) do
        Dumper.setup do |c|
          c.dumps_location = dumps_location
        end
      end

      after(:each) do
        FileUtils.rm_r('tmp1')
      end

      it 'creates folders' do
        object.execute_with_dump("some_dump") { }
        expect(Dir.exists?(dumps_location)).to be(true)
      end
    end

    context 'postgres' do
      let(:database) { 'dumper_test' }
      let(:db) { Sequel.connect(adapter: 'postgres', database: database) }

      before(:each) do
        Kernel.system('createdb', database)

        Dumper.setup do |c|
          c.database = database
        end
      end

      after(:each) do
        db.disconnect
        Kernel.system('dropdb', database)
        FileUtils.rm_r('tmp')
      end

      it 'creates dump file' do
        object.execute_with_dump("some_dump") { }
        expect(File.exists?("tmp/dumper/some_dump.dump")).to be(true)
      end

      context 'dump content' do
        before(:each) do
          object.execute_with_dump("some_dump") do
            db.run("create table t (a text, b text)")
            db.run("insert into t values ('a', 'b')")
          end
        end

        it 'inserts some info' do
          expect(db[:t].map([:a, :b])).to eq([['a', 'b']])
        end

        it 'uses dump content if dump exists' do
          db.run("delete from t")
          object.execute_with_dump("some_dump") { }
          expect(db[:t].map([:a, :b])).to eq([['a', 'b']])
        end
      end
    end

    context 'mysql' do
      let(:database) { 'dumper_test' }
      let(:db) { Sequel.connect(adapter: 'mysql2') }

      before(:each) do
        db.run("CREATE DATABASE #{database}")
        Dumper.setup do |c|
          c.database = database
        end
      end

      after(:each) do
        db.run("DROP DATABASE #{database}")

        db.disconnect
        FileUtils.rm_r('tmp')
      end

      it 'creates dump file' do
        object.execute_with_dump("some_dump") { }
        expect(File.exists?("tmp/dumper/some_dump.dump")).to be(true)
      end

      context 'dump content' do
        before(:each) do
          object.execute_with_dump("some_dump") do
            db.run("create table t (a text, b text)")
            db.run("insert into t values ('a', 'b')")
          end
        end

        it 'inserts some info' do
          expect(db[:t].map([:a, :b])).to eq([['a', 'b']])
        end

        it 'uses dump content if dump exists' do
          db.run("delete from t")
          object.execute_with_dump("some_dump") { }
          expect(db[:t].map([:a, :b])).to eq([['a', 'b']])
        end
      end
    end
  end
end
