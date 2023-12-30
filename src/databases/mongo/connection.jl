using Mongoc
using JSON

struct MongoDB <: NoSQLDB
    database::Mongoc.Database
end

data_format(db::MongoDB)      = Mongoc.BSON
collection_names(db::MongoDB) = Mongoc.get_collection_names(db.database)
collection(db::MongoDB, ::Type{T}) where T = db.database[collection(T)]
database(db::MongoDB)         = db.database
# Symbol representation to allow `connect(:mongo, ...)`
Base.Symbol(::Type{<:MongoDB})  = :mongo
connectionstring(db::MongoDB)   = "$(last(split(database(db).client.uri, "://"))) => $(database(db).name)"

# Dispatcher for `connect` @ src/connections.jl
function connect(::Type{MongoDB}, dbname::String; kwargs...) ::Connection
    mongoclient = mongo_client(;kwargs...)
    mongodb     = mongo_db(mongoclient, dbname)
    return Connection(MongoDB(mongodb))
end

function connect(::Type{MongoDB}, dbname::String, uri::String) ::Connection
    mongoclient = mongo_client(uri)
    mongodb     = mongo_db(mongoclient, dbname)
    return Connection(MongoDB(mongodb))
end

function mongo_client(;
    host         ::String = "localhost", 
    port         ::Int    =  27017, 
    username     ::String = "", 
    password     ::String = "", 
    authSource   ::String = "", 
    authMechanism::String = "",
    kwargs...
) ::Mongoc.Client
    uri = """mongodb://"""
    if !isempty(username) && !isempty(password)
        uri *= "$username:$password@" 
    end
    uri *= "$host:$port"
    if !isempty(authSource)
        uri *= "/?authSource=$authSource" 
    end
    if !isempty(authSource) &&  !isempty(authMechanism)  
        uri *= "&authMechanism=$authMechanism" 
    elseif !isempty(authMechanism)
        uri *= "/?authMechanism=$authMechanism"
    end
    
    return mongo_client(uri)
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

