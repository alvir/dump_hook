require "spec_helper"
require "ostruct"

describe ConnectionArgs do
  describe ".for_postgres" do
    it "returns correct URI if database is given" do
      settings = OpenStruct.new(database: "dump_hook")
      expect(ConnectionArgs.for_postgres(settings)).to eq([
        "-d", "postgres:///dump_hook"
      ])
    end

    it "returns correct URI if database, host are given" do
      settings = OpenStruct.new(database: "dump_hook", host: "localhost")
      expect(ConnectionArgs.for_postgres(settings)).to eq([
        "-d", "postgres://localhost/dump_hook"
      ])
    end

    it "returns correct URI if database, user are given" do
      settings = OpenStruct.new(database: "dump_hook", username: "root")
      expect(ConnectionArgs.for_postgres(settings)).to eq([
        "-d", "postgres://root@/dump_hook"
      ])
    end

    it "returns correct URI if database, user, password are given" do
      settings = OpenStruct.new(database: "dump_hook", username: "root", password: "epyfnm")
      expect(ConnectionArgs.for_postgres(settings)).to eq([
        "-d", "postgres://root:epyfnm@/dump_hook"
      ])
    end

    it "returns correct URI if database, host, user, password are given" do
      settings = OpenStruct.new(
        database: "dump_hook", host: "localhost", username: "root", password: "epyfnm"
      )
      expect(ConnectionArgs.for_postgres(settings)).to eq([
        "-d", "postgres://root:epyfnm@localhost/dump_hook"
      ])
    end

    it "returns correct URI if database, host, port, user, password are given" do
      settings = OpenStruct.new(
        database: "dump_hook", host: "localhost", port: 4321, username: "root", password: "epyfnm"
      )
      expect(ConnectionArgs.for_postgres(settings)).to eq([
        "-d", "postgres://root:epyfnm@localhost:4321/dump_hook"
      ])
    end
  end
end
