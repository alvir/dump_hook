require 'spec_helper'
require 'sequel'

describe DumpHook do
  it 'has a version number' do
    expect(DumpHook::VERSION).not_to be nil
  end

  describe '.setup' do
    context 'default settings' do
      before(:each) do
        DumpHook.setup do |_|
        end
      end

      it 'sets dumps_location' do
        expect(DumpHook.settings.dumps_location).to eq('tmp/dump_hook')
      end

      it 'sets remove_old_dumps' do
        expect(DumpHook.settings.remove_old_dumps).to eq(true)
      end

      it 'sets database' do
        expect(DumpHook.settings.database).to eq('please set database')
      end

      it 'does not set actual' do
        expect(DumpHook.settings.actual).to be nil
      end
    end

    context 'custom settings' do
      let(:new_location) { 'new_location' }
      let(:new_remove_old_dumps) { false }
      let(:new_database) { 'new_database' }
      let(:new_username) { 'new_username' }
      let(:new_host) { 'example.com' }
      let(:new_port) { 600 }
      let(:new_actual) { 'actual_with_some_phrase' }

      it 'sets dumps_location' do
        DumpHook.setup { |c| c.dumps_location = new_location }
        expect(DumpHook.settings.dumps_location).to eq(new_location)
      end

      it 'sets remove_old_dumps' do
        DumpHook.setup { |c| c.remove_old_dumps = new_remove_old_dumps }
        expect(DumpHook.settings.remove_old_dumps).to eq(new_remove_old_dumps)
      end

      it 'sets database' do
        DumpHook.setup { |c| c.database = new_database }
        expect(DumpHook.settings.database).to eq(new_database)
      end

      it 'sets username' do
        DumpHook.setup { |c| c.username = new_username }
        expect(DumpHook.settings.username).to eq(new_username)
      end

      it 'sets host' do
        DumpHook.setup { |c| c.host = new_host }
        expect(DumpHook.settings.host).to eq(new_host)
      end

      it 'sets port' do
        DumpHook.setup { |c| c.port = new_port }
        expect(DumpHook.settings.port).to eq(new_port)
      end

      it 'sets actual' do
        DumpHook.setup { |c| c.actual = new_actual }
        expect(DumpHook.settings.actual).to eq(new_actual)
      end
    end
  end

  describe '.execute_with_dump' do
    let(:object) { Object.new }

    before(:each) do
      object.extend(DumpHook)
    end

    context 'folders creation' do
      let(:dumps_location) { "tmp1/tmp2/tmp3" }

      before(:each) do
        DumpHook.setup do |c|
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
      let(:database) { 'dump_hook_test' }
      let(:db) { Sequel.connect(adapter: 'postgres', database: database) }

      before(:each) do
        Kernel.system('createdb', database)

        DumpHook.setup do |c|
          c.database = database
        end
      end

      after(:each) do
        db.disconnect
        Kernel.system('dropdb', database)
        FileUtils.rm_r('tmp')
        DumpHook.recreate = nil
      end

      it 'creates dump file' do
        object.execute_with_dump("some_dump") { }
        expect(File.exist?("tmp/dump_hook/some_dump.dump")).to be(true)
      end

      context "[actual]" do
        context "in settings" do
          before(:each) do
            DumpHook.settings.actual = 1
          end

          context "when actual is permanent" do
            before(:each) do
              object.execute_with_dump("some_dump") { }
            end

            it 'creates dump file' do
              expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual1.dump")
            end
          end

          context "when actual is changing" do
            before(:each) do
              object.execute_with_dump("some_dump") { }
              DumpHook.settings.actual = 2
            end

            it "creates a new dump file and remove old dumps by default" do
              object.execute_with_dump("some_dump") { }
              expect(Dir.entries("tmp/dump_hook")).to_not include("some_dump_actual1.dump")
              expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual2.dump")
            end

            context "and remove_old_dumps is disabled" do
              before(:each) do
                DumpHook.settings.remove_old_dumps = false
              end

              it "creates a new dump file" do
                object.execute_with_dump("some_dump") { }
                expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual1.dump")
                expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual2.dump")
              end
            end
          end
        end

        context "in parameters" do
          context "when actual is permanent" do
            before(:each) do
              object.execute_with_dump("some_dump", actual: 1) { }
            end

            it 'creates dump file' do
              expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual1.dump")
            end
          end

          context "when actual is changing" do
            before(:each) do
              object.execute_with_dump("some_dump", actual: 1) { }
            end

            it "creates a new dump file and remove old dumps by default" do
              object.execute_with_dump("some_dump", actual: 2) { }
              expect(Dir.entries("tmp/dump_hook")).to_not include("some_dump_actual1.dump")
              expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual2.dump")
            end

            context "and remove_old_dumps is disabled" do
              before(:each) do
                DumpHook.settings.remove_old_dumps = false
              end

              it "creates a new dump file" do
                object.execute_with_dump("some_dump", actual: 2) { }
                expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual1.dump")
                expect(Dir.entries("tmp/dump_hook")).to include("some_dump_actual2.dump")
              end
            end
          end
        end
      end

      context "recreate" do
        before(:each) do
          db.run("create table t (a text, b text)")
          object.execute_with_dump("some_dump") do
            db.run("insert into t values ('a', 'b')")
          end
        end

        def new_dump
          object.execute_with_dump("some_dump") do
            db.run("insert into t values ('a', 'b')")
            db.run("insert into t values ('c', 'd')")
          end
        end

        context "when recreate is disabled" do
          it "doesn't change file" do
            expect { new_dump }.to_not change { File.read("tmp/dump_hook/some_dump.dump") }
          end
        end

        context "when recreate is enabled" do
          before(:each) do
            DumpHook.settings.recreate = true
          end

          it "changes file just the first time" do
            expect { new_dump }.to change { File.read("tmp/dump_hook/some_dump.dump") }
            expect { new_dump }.to_not change { File.read("tmp/dump_hook/some_dump.dump") }
          end

          context "and there are more than one dump" do
            before(:each) do
              object.execute_with_dump("another_dump") do
                db.run("insert into t values ('e', 'f')")
              end
            end

            it "changes file just the first time" do
              expect { new_dump }.to change { File.read("tmp/dump_hook/some_dump.dump") }
                                 .and not_change { File.read("tmp/dump_hook/another_dump.dump") }
            end
          end
        end

        context "when recreate is enabled using ENV" do
          before(:each) do
            ENV["DUMP_HOOK"] = "recreate"
          end

          it "changes file" do
            expect { new_dump }.to change { File.read("tmp/dump_hook/some_dump.dump") }
            expect { new_dump }.to_not change { File.read("tmp/dump_hook/some_dump.dump") }
          end
        end

        context "when recreate is enabled using parameters" do
          def new_dump
            object.execute_with_dump("some_dump") do
              db.run("insert into t values ('a', 'b')")
              db.run("insert into t values ('c', 'd')")
            end
          end

          it "changes file" do
            expect { new_dump }.to change { File.read("tmp/dump_hook/some_dump.dump") }
            expect { new_dump }.to_not change { File.read("tmp/dump_hook/some_dump.dump") }
          end
        end
      end

      context "dump content" do
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
      let(:database) { 'dump_hook_test' }
      let(:username) { 'root' }
      let(:db) { Sequel.connect(adapter: 'mysql2', user: username) }

      before(:each) do
        db.run("CREATE DATABASE #{database}")
        db.run("USE #{database}")
        DumpHook.setup do |c|
          c.database = database
          c.database_type = 'mysql'
          c.username = username
        end
      end

      after(:each) do
        db.run("DROP DATABASE #{database}")

        db.disconnect
        FileUtils.rm_r('tmp')
      end

      it 'creates dump file' do
        object.execute_with_dump("some_dump") { }
        expect(File.exist?("tmp/dump_hook/some_dump.dump")).to be(true)
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
