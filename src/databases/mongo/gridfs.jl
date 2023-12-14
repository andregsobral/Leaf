
abstract type GridFSData end

dataformat(::Type{T}) where T <: GridFSData  = "gridfsdata"

find(    ::Type{T}, query::Dict=Dict(); options = nothing) where T <: GridFSData = find(    globalconn(), T, query, options = options)
find_one(::Type{T}, query::Dict=Dict(); options = nothing) where T <: GridFSData = find_one(globalconn(), T, query, options = options)
delete(  ::Type{T}, query::Dict)                           where T <: GridFSData = delete(  globalconn(), T, query)
download(file_id::AbstractString, file_path::AbstractString)                     = download(globalconn(), file_id, file_path)

function upload(::Type{T}, file_id::AbstractString, file_path::AbstractString, metadata::Dict=Dict()) where T <: GridFSData
    return upload(globalconn(), T, file_id, file_path, metadata)
end

function find(conn::Connection, ::Type{T}, query::Dict=Dict(); options = nothing) where T <: GridFSData
    bucket = Mongoc.Bucket(database(conn))
    query["metadata.type"] = dataformat(T)
    result = Mongoc.find(
        bucket, 
        Mongoc.BSON(query),
        options = isnothing(options) ? Mongoc.BSON() : Mongoc.BSON(options)
    )
    return collect(result)
end

function find_one(conn::Connection, ::Type{T}, query::Dict=Dict(); options = nothing) where T <: GridFSData
    res = Leaf.find(conn, T, query, options = options)
    return !isempty(res) ? first(res) : nothing
end

function delete(conn::Connection, ::Type{T}, query::Dict) where T <: GridFSData
    bucket = Mongoc.Bucket(database(conn))
    return Mongoc.delete(bucket, Mongoc.BSON(query))
end

function download(conn::Connection, file_id::AbstractString, file_path::AbstractString)
    bucket = Mongoc.Bucket(database(conn))
    return Mongoc.download(bucket, file_id, file_path)
end

function upload(conn::Connection, ::Type{T}, file_id::AbstractString, file_path::AbstractString, metadata::Dict=Dict()) where T <: GridFSData
    bucket = Mongoc.Bucket(database(conn))
    metadata["type"] = dataformat(T)
    return Mongoc.upload(
        bucket, file_id, file_path, 
        metadata = Mongoc.BSON(metadata)
    )
end