module ConnectionArgs
  extend self
  PG_HOST_PLACEHOLDER = "dummy-postgres-host"

  def for_postgres(settings)
    userinfo = [settings.username, settings.password].compact.join(":")
    uri = URI::Generic.new(
      "postgres",
      userinfo,
      settings.host || PG_HOST_PLACEHOLDER,
      settings.port,
      nil,
      "/#{settings.database}",
      nil,
      nil,
      nil
    )
    ["-d", uri.to_s.sub(PG_HOST_PLACEHOLDER, "")]
    # args = ['-d', settings.database]
    # args.concat(['-U', settings.username]) if settings.username
    # args.concat(['-h', settings.host]) if settings.host
    # args.concat(['-p', settings.port]) if settings.port
    # args
  end
end
