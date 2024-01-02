using Mongoc
using JSON

struct MongoDB <: NoSQLDB
    database::Mongoc.Database
    uri     ::String
    metadata::Dict
end

# --- Acessors
uri(db::MongoDB)       = db.uri
metadata(db::MongoDB)  = db.metadata
database(db::MongoDB) = db.database
collection_names(db::MongoDB) = Mongoc.get_collection_names(db.database)

# --- Configurations
collection(db::MongoDB, ::Type{T}) where T = db.database[collection(T)]
data_format(db::MongoDB) = Mongoc.BSON
Base.Symbol(::Type{<:MongoDB})  = :mongo # Symbol representation to allow `connect(:mongo, ...)`
metadata(::Type{<:MongoDB}) = Dict(
    "host"          => "localhost", 
    "port"          => 27017, 
    "username"      => nothing, 
    "password"      => nothing, 
    "authSource"    => nothing, 
    "authMechanism" => nothing,
    "dbname"        => nothing
)

# Dispatcher for `connect` @ src/connections.jl (kwarg based)
function connect(::Type{MongoDB}, dbname::String; kwargs...) ::Connection
    mongoclient, uri, metadata = mongo_client(;kwargs...)
    mongodb = mongo_db(mongoclient, dbname)
    metadata["dbname"] = dbname
    return Connection(MongoDB(mongodb, uri, metadata))
end

# Dispatcher for `connect` @ src/connections.jl (uri based)
function connect(::Type{MongoDB}, dbname::String, uri::String) ::Connection
    metadata    = parse_uri(uri)
    mongoclient = mongo_client(uri)
    mongodb     = mongo_db(mongoclient, dbname)
    metadata["dbname"] = dbname
    return Connection(MongoDB(mongodb, uri, metadata))
end

function mongo_client(;
    host         ::String = "localhost", 
    port         ::Int    =  27017, 
    username     ::String = "", 
    password     ::String = "", 
    authSource   ::String = "", 
    authMechanism::String = "",
    kwargs...
)
    client_metadata = metadata(MongoDB)
    client_metadata["host"] = host
    client_metadata["port"] = port
    
    uri = """mongodb://"""
    if !isempty(username) && !isempty(password)
        uri *= "$username:$password@"
        client_metadata["username"] = username
        client_metadata["password"] = password
    end
    uri *= "$host:$port"
    if !isempty(authSource)
        client_metadata["authSource"] = authSource
        uri *= "/?authSource=$authSource" 
    end
    if !isempty(authSource) &&  !isempty(authMechanism)  
        uri *= "&authMechanism=$authMechanism"
        client_metadata["authMechanism"] = authMechanism
    elseif !isempty(authMechanism)
        uri *= "/?authMechanism=$authMechanism"
        client_metadata["authMechanism"] = authMechanism
    end
    
    return mongo_client(uri), uri, client_metadata
end

function mongo_client(uri::String) ::Mongoc.Client
    mongoclient = Mongoc.Client(uri)
    ping = Mongoc.ping(mongoclient)
    if haskey(ping, "ok") && ping["ok"] == true
        return mongoclient
    end
    throw(ConnectionException("MongoDB server was not found -> $uri"))
end

function mongo_db(client::Mongoc.Client, database_name::String) ::Mongoc.Database
    return client[database_name]
end

function parse_uri(uri::String) ::Dict
    # --- base metadata
    client_metadata = metadata(MongoDB)
    conn_string = last(split(uri, "mongodb://"))

    # --- main conn and conn args
    conn_string = split(conn_string, "/?")
    conn_args   = length(conn_string) > 1 ? last(conn_string) : nothing
    conn_string = first(conn_string)
    
    # --- splint main conn args
    conn_string = split(conn_string, "@")
    conn_string = reverse(conn_string)
    
    # --- host and port
    host, port = split(conn_string[1], ":")
    client_metadata["host"] = host
    if !isnothing(port)
        try
            client_metadata["port"] = Base.parse(Int, port)
        catch err
            @warn "Could not parse port to integer value: $port"
        end
    end

    # --- username:password
    if length(conn_string) > 1
        username, password = split(conn_string[2], ":")
        client_metadata["username"] = username
        if !isnothing(password)
            client_metadata["password"] = password
        end    
    end

    # --- authSource && authMecanism
    if !isnothing(conn_args)
        for arg in split(conn_args, "&")
            k,v = split(arg, "=")
            client_metadata[k] = v
        end
    end

    return client_metadata
end

findmeta(db::MongoDB, field::Symbol) = Base.get(metadata(db), string(field), nothing)

username(db::MongoDB)      = findmeta(db, :username)
password(db::MongoDB)      = findmeta(db, :password)   
authSource(db::MongoDB)    = findmeta(db, :authSource)   
authMechanism(db::MongoDB) = findmeta(db, :authMechanism)   
host(db::MongoDB)          = findmeta(db, :host)   
port(db::MongoDB)          = findmeta(db, :port)   
dbname(db::MongoDB)        = findmeta(db, :dbname)

username(conn::Connection)      = username(db(conn))
password(conn::Connection)      = password(db(conn))   
authSource(conn::Connection)    = authSource(db(conn))   
authMechanism(conn::Connection) = authMechanism(db(conn))   
host(conn::Connection)          = host(db(conn))   
port(conn::Connection)          = port(db(conn))   
dbname(conn::Connection)        = dbname(db(conn))

