# frozen_string_literal: true

UbiCli.on("pg").run_on("create") do
  desc "Create a PostgreSQL database"

  options("ubi pg location/pg-name create [options]", key: :pg_create) do
    on("-f", "--flavor=type", "flavor (standard, paradedb, lantern)")
    on("-h", "--ha-type=type", "replication type (none, async, sync)")
    on("-s", "--size=size", "server size (standard-{2,4,8,16,30,60})")
    on("-S", "--storage-size=size", "storage size GB (64, 128, 256)")
    on("-v", "--version=version", "PostgreSQL version (16, 17)")
  end

  run do |opts|
    params = underscore_keys(opts[:pg_create])
    params["size"] ||= Prog::Vm::Nexus::DEFAULT_SIZE
    post(pg_path, params) do |data|
      ["PostgreSQL database created with id: #{data["id"]}"]
    end
  end
end
