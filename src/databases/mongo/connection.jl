using Mongoc
using JSON

struct MongoDB <: NoSQLDB
    database::Mongoc.Database
end

data_format(db::MongoDB)                   = Mongoc.BSON
collection_names(db::MongoDB)              = Mongoc.get_collection_names(db.database)
collection(db::MongoDB, ::Type{T}) where T = db.database[collection(T)]
database(db::MongoDB)                      = db.database
# Symbol representation to allow `connect(:mongo, ...)`
Base.Symbol(::Type{<:MongoDB})       = :mongo
connectionstring(db::MongoDB) = "$(last(split(database(db).client.uri, "://"))) => $(database(db).name)"

# ----- Connection API
connect(db::Mongoc.Database)               = Connection(MongoDB(db))
connect(client::Mongoc.Client, db::String) = connect(client[db])

# Dispatcher for `connect` @ src/connections.jl
connect(::Type{MongoDB}, host::String, dbname::String; port::Int=27017) ::Connection  = connect(Mongoc.Client(host, port), dbname)

# Dispatcher for `connect` @ src/connections.jl
function connect(::Type{MongoDB}, host::String, username::String, password::String, dbname::String; 
    port          = nothing, 
    authSource    = nothing, 
    authMechanism = nothing
) ::Connection
    
    uri = geturi(host, username, password, port, authSource, authMechanism)
    return Connection(Mongoc.Client(uri)[dbname])
end

function geturi(host::String, username::String, password::String, port=nothing, authSource=nothing, authMechanism=nothing) ::String
    uri = """mongodb://$username:$password@$host"""
    if !isnothing(port)         
        uri *= ":$port" 
    end
    if !isnothing(authSource)
        uri *= "/?authSource=$authSource" 
    end
    if !isnothing(authSource) &&  !isnothing(authMechanism)  
        uri *= "&authMechanism=$authMechanism" 
    elseif !isnothing(authMechanism)
        uri *= "/?authMechanism=$authMechanism"
    end
    return uri
end

include("utils.jl")
include("crud.jl")
include("gridfs.jl")
