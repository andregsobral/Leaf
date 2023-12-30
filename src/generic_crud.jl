
# ===========================
#   Generic CRUD
# ===========================

function find(conn::Connection, ::Type{T}, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    result, to_deserialize = find(collection(conn, T), qry, options = qry_opts)
    if !to_deserialize
        return result
    end
    return isempty(result) ? Vector{T}() : deserialize.(T, result)
end

function find_one(conn::Connection, ::Type{T}, query; options = nothing) where T
    qry, qry_opts          = parse_input(conn, T, query, options)
    result, to_deserialize = find_one(collection(conn, T), qry, options = qry_opts)
    if !to_deserialize
        return result
    end
    return isnothing(result) ? nothing : deserialize(T, result)
end

function delete(conn::Connection, ::Type{T}, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    return delete(collection(conn, T), qry, options = qry_opts)
end

function delete_one(conn::Connection, ::Type{T}, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    return delete_one(collection(conn, T), qry, options = qry_opts)
end

function create(conn::Connection, data::T; options = nothing) where T
    assert_valid_data(data, "create")
    db_data = serialize(conn, data)
    return create(collection(conn, T), db_data)
end
 
function create(conn::Connection, data::Vector{T}; options = nothing) where T
    assert_valid_data(data, "create")
    db_data = [serialize(conn, entry) for entry in data]
    return create(collection(conn, T), db_data, options = parse_options(conn, options))
end

function update(conn::Connection, ::Type{T}, data, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    db_data = serialize(conn, data)
    return update(collection(conn, T), db_data, qry, options = qry_opts)
end

function update(conn::Connection, ::Type{T}, pipeline::Union{String,Dict}, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    return update(collection(conn, T), pipeline, qry, options = qry_opts)
end

function update_one(conn::Connection, ::Type{T}, data, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    db_data = serialize(conn, data)
    return update_one(collection(conn, T), db_data, qry, options = qry_opts)
end

function update_one(conn::Connection, ::Type{T}, pipeline::Union{String,Dict}, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    return update_one(collection(conn, T), pipeline, qry, options = qry_opts)
end

function update_one(conn::Connection, data::T, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    assert_valid_data(data, "update")
    db_data = serialize(conn, data)
    return update_one(collection(conn, T), db_data, qry, options = qry_opts)
end

function count(conn::Connection, ::Type{T}, query; options = nothing) where T
    qry, qry_opts = parse_input(conn, T, query, options)
    return count(collection(conn, T), qry, options = qry_opts)
end

function drop(conn::Connection, ::Type{T}) where T
    if collection(T) in collection_names(conn)
        return drop(collection(conn, T))
    end
    @warn "Collection with name \"$(collection(T))\" does not exist in the database."
    return nothing
end

function aggregate(conn::Connection, ::Type{T}, pipeline; serialize_as = nothing) where T
   result = aggregate(collection(conn, T), pipeline)
   return isnothing(serialize_as) ? result : deserialize.(serialize_as, result)
end

function raw(conn::Connection, query)
    return raw(database(conn), query)
end

# ==============================================
#   Overloads for kwargs
# ==============================================

function find(conn::Connection, ::Type{T}; kwargs...) where T
    query, options = crud_query(conn, T, :find,  kwargs)
    return find(conn, T, query, options = options)
end

function find_one(conn::Connection, ::Type{T}; kwargs...) where T
    query, options = crud_query(conn, T, :find_one,  kwargs)
    return find_one(conn, T, query, options = options)
end

function delete(conn::Connection, ::Type{T}; kwargs...) where T
    query, options = crud_query(conn, T, :delete,  kwargs)
    return delete(conn, T, query, options = options)
end

function delete_one(conn::Connection, ::Type{T}; kwargs...) where T 
    query, options = crud_query(conn, T, :delete_one,  kwargs)
    return delete_one(conn, T, query, options = options)
end

function update(conn::Connection, ::Type{T}, data; kwargs...) where T
    query, options = crud_query(conn, T, :update,  kwargs)
    return update(conn, T, data, query, options = options)
end

function update_one(conn::Connection, data::T; kwargs...) where T
    query, options = crud_query(conn, T, :update_one,  kwargs)
    return update_one(conn, data, query, options = options)
end

function update_one(conn::Connection, ::Type{T}, data; kwargs...) where T
    query, options = crud_query(conn, T, :update_one,  kwargs)
    return update_one(conn, T, data, query, options = options)
end

function count(conn::Connection, ::Type{T}; kwargs...) where T
    query, options = crud_query(conn, T, :count,  kwargs)
    return count(collection(conn, T), query, options = options)
end

function raw(conn::Connection; kwargs...)
    return raw(database(conn), [ string(k) => v for (k,v) in kwargs ])
end

# ==============================================
#   Overloads for global connection
# ==============================================

find(      ::Type{T}      ; kwargs...) where T = find(      globalconn(), T; kwargs...)
find_one(  ::Type{T}      ; kwargs...) where T = find_one(  globalconn(), T; kwargs...)
delete(    ::Type{T}      ; kwargs...) where T = delete(    globalconn(), T; kwargs...)
delete_one(::Type{T}      ; kwargs...) where T = delete_one(globalconn(), T; kwargs...)
update(    ::Type{T}, data; kwargs...) where T = update(    globalconn(), T, data; kwargs...)
update_one( data::T        ; kwargs...) where T = update_one(globalconn(), data; kwargs...)
update_one(::Type{T}, data; kwargs...) where T = update_one(globalconn(), T, data; kwargs...)
count(     ::Type{T}      ; kwargs...) where T = count(     globalconn(), T; kwargs...)
raw(; kwargs...)                               = raw(       globalconn(); kwargs...)

find(      ::Type{T},       query; options = nothing) where T = find(      globalconn(), T,       query, options = options)
find_one(  ::Type{T},       query; options = nothing) where T = find_one(  globalconn(), T,       query, options = options)
delete(    ::Type{T},       query; options = nothing) where T = delete(    globalconn(), T,       query, options = options)
delete_one(::Type{T},       query; options = nothing) where T = delete_one(globalconn(), T,       query, options = options)
update(    ::Type{T}, data, query; options = nothing) where T = update(    globalconn(), T, data, query, options = options)
update_one(::Type{T}, data, query; options = nothing) where T = update_one(globalconn(), T, data, query, options = options)
count(     ::Type{T},       query; options = nothing) where T = count(     globalconn(), T,       query, options = options)

update_one(data::T,         query; options = nothing) where T = update_one(globalconn(), data,    query, options = options)
create(    data::T;                options = nothing) where T = create(    globalconn(), data,           options = options)
create(    data::Vector{T};        options = nothing) where T = create(    globalconn(), data,           options = options)
aggregate( ::Type{T}, pipeline; serialize_as = nothing) where T = aggregate(globalconn(), T, pipeline, serialize_as = serialize_as)

drop(::Type{T}) where T = drop(globalconn(), T)
raw(query)              = raw(globalconn(), query)

# ==============================================
#   CRUD helpers
# ==============================================

function serialize(conn::Connection, business_data)
    return serialize(db(conn), business_data)
end

function serialize(db::Database, business_data)
    return Base.convert(data_format(db), business_data)
end

function deserialize(::Type{T}, db_data) where T
    return Base.convert(T, db_data)
end

# ==============================================
#  Redo after defining the Schema concept
# ==============================================

function show_invalid_data(data::T, action::String) where T
    @info "--- Invalid data ---"
    @show data
    @info "--------------------"
    throw(ValidateException("Tried to $action an invalid $(T) in the database"))
end

assert_valid_data(data,        action::String) = !validate(data) ? show_invalid_data(data, action) : true
assert_valid_data(data::Array, action::String) = [ assert_valid_data(entry, action) for entry in data ]
