# ============================================================================
#  Connection
# ============================================================================

struct Connection
    database :: Database
end
const DBCONN = Ref{Connection}()
globalconn!(conn::Connection)      = DBCONN[] = conn
connectionstring(conn::Connection) = connectionstring(db(conn))

db(conn::Connection)                    = conn.database
collection_names(conn::Connection)      = collection_names(db(conn))
collection(conn::Connection, ::Type{T}) where T = collection(db(conn), T)
database(conn::Connection)              = database(db(conn))

function globalconn()
    try 
        return DBCONN[]
    catch err
        return nothing
    end
end

connectionstring() = connectionstring(db(globalconn()))
db()               = db(globalconn())
collection_names() = collection(globalconn())
database()         = database(globalconn())

# each Database subtype should provide its Symbol representation
Base.Symbol(::Type{D}) where D<:Database = @error("Abstract type Database does not provide a symbolic representation. Base.Symbol should be implemented for type $D")
 # auto-dispatch for concretes
Base.Symbol(::D) where D<:Database  = Base.Symbol(D)
Base.Symbol(c::Connection)          = Base.Symbol(db(c))
#=  
    Define interface dbtypes() for adding new supported Database(s)
    Define as function to allow user overload
=#
"""
    dbtypes()
    
The list of supported concrete Database(s)
"""
dbtypes() = Dict(:mongo=>MongoDB)

function connect(type::Symbol, args...; kwargs...) ::Connection
    available_error_info() = unique(collect(Base.Symbol.(dbtypes())))
    
    @assert haskey(dbtypes(), type) "Unknown Database type: \"$(type)\".\nAvailable types are:\n\t- $(available_error_info())"
    return connect(dbtypes()[type], args...; kwargs...)
end


# ============================================================================
#  Support for the syntax using "." to call crud functions over a connection
#   - connection.find(...)
#   - connection.create(...)
#   .... and so on
# ============================================================================
struct Dispatcher
    conn::Connection
    func::Function
end

function (dispatch::Dispatcher)(args...; kwargs...)
    return dispatch.func(dispatch.conn, args...; kwargs...)
end

function is_api_func(sym::Symbol)
    return sym in [ :find  , :find_one,   :create, :count,
                    :update, :update_one, :delete, :delete_one,
                    :drop  , :aggregate,  :raw]
end

function Base.getproperty(conn::Connection, sym::Symbol)
    if is_api_func(sym)
        return Dispatcher(conn, getfield(Leaf, sym))
    end
    return getfield(conn, sym) # fallback to getfield
end

# =======================
#   Parsing input data
# =======================

# ---- Connection level 
parse_input(  conn::Connection, T, query, options) = parse_query(conn, T, query), parse_options(conn, options)
parse_query(  conn::Connection, T, query)          = parse_query(db(conn), T, query)
parse_options(conn::Connection, options)           = parse_options(db(conn), options)

crud_query(   conn::Connection, T, func::Symbol, kwargs) = crud_query(db(conn), T, func, kwargs)

# ---- Database level
function parse_query(db::Database, T, query)
    return parse_query(T, query)
end

function parse_query(db::Database, T, query::String) 
    qr = !isempty(query) ? JSON.parse(query) : Dict()
    return parse_query(T, qr)
end

function parse_query(db::Database, T, query::Dict)
    qr = Dict{String, Any}(string(k) => v for (k,v) in query)
    return parse_query(T, qr)
end

# -- Overload to get default parsing for specific type
parse_query(T, query::Dict) = query

function parse_options(db::Database, options)
    return options
end

function parse_options(db::Database, options::String)
    return !isempty(options) ? JSON.parse(options) : nothing
end

function crud_query(db::Database, T, func::Symbol, kwargs)
    query   = parse_query(db, T, Dict(kwargs))
    options = nothing
    if haskey(query, "_options")
        options = query["_options"]
        delete!(query, "_options")
    end
    return query, options
end
