# ---------------------------------------------------
#   CRUD Mongo methods
# ---------------------------------------------------
"""
    Lookup data in the database.
    - find:     returns an array of objects, if they exist  (object vector or empty)
    - find_one: returns a single object,     if it   exists (object or nothing)
"""
function find(collection::Mongoc.Collection, query::Dict=Dict(); options = nothing)
    if haskey(query, "_id") query["_id"] = bsonid(query["_id"]) end
    options = isnothing(options) ? Dict() : options
    result = collect(
        Mongoc.find(
            collection, 
            Mongoc.BSON(query), 
            options = Mongoc.BSON(options)
    ))
    return result, !haskey(options, "projection")
end

function find_one(collection::Mongoc.Collection, query::Dict=Dict(); options = nothing)
    if haskey(query, "_id") query["_id"] = bsonid(query["_id"]) end
    options = isnothing(options) ? Dict() : options
    result =  Mongoc.find_one(
        collection, 
        Mongoc.BSON(query), 
        options = Mongoc.BSON(options)
    )
    return result, !haskey(options, "projection")
end

"""
    Insert data to the database.
    - create: 
    Inserts an object or a collection of objects to the database.
    Returns either an object or a Dict() with the number of objects inserted and the inserted data
"""
function create(collection::Mongoc.Collection, document::Mongoc.BSON; options = nothing)
    res  = Mongoc.insert_one(
        collection, 
        document, 
        options = isnothing(options) ? Mongoc.BSON() : Mongoc.BSON(options)
    )
    status = res.reply["insertedCount"] == 1 ? 
        (insertion = true,  insertedCount = res.reply["insertedCount"], reply = res.reply, msg = "OK",) :
        (insertion = false, insertedCount = res.reply["insertedCount"], reply = res.reply, msg = "Creation of 1 Element didn't occur as expected.")

    return (
        _id    = isnothing(res.inserted_oid) ? document["_id"] : res.inserted_oid,
        status = status
    )
end

function create(collection::Mongoc.Collection, documents::Array; options = nothing)
    bson_bulk_options   = nothing
    bson_insert_options = nothing
    if !isnothing(options) && options isa Dict
        bson_bulk_options   = haskey(options, "bulk")   ? Mongoc.BSON(options["bulk"])   : bson_bulk_options
        bson_insert_options = haskey(options, "insert") ? Mongoc.BSON(options["insert"]) : bson_insert_options
    end
    res = Mongoc.insert_many(
        collection, 
        documents, 
        bulk_options   = bson_bulk_options, 
        insert_options = bson_insert_options
    )
    status = res.reply["nInserted"] == length(documents) ?
        (insertion = true,  insertedCount = res.reply["nInserted"], reply = res.reply, msg = "OK",) :
        (insertion = false, insertedCount = res.reply["nInserted"], reply = res.reply, msg = "Creation of multiple objects didn't occur as expected.")

    # --- Collect ids of data created in the db
    ids = []
    for i in eachindex(documents)
        id = isnothing(res.inserted_oids[i]) ? documents[i]["_id"] : res.inserted_oids[i]
        push!(ids, id)
    end

    # --- response
    return (
        _id    = ids,
        status = status
    )
end

"""
    Updates one entry of the database.
    - document based: based on the query, updates one entry to the document.
    - dynamic pipeline: set your update pipeline and update one entry based on the query.
"""
function update_one(collection::Mongoc.Collection, document::Mongoc.BSON, query::Dict=Dict(); options = nothing)
    if haskey(document, "_id")
        query["_id"] = bsonid(document["_id"])
        document     = Mongoc.BSON([k=>v for (k,v) in document if k != "_id"]...) 
    end
    if isempty(query)
        @warn "Update query is empty and the document does not have an '_id' field. Was not able to update any entry."
        return (
            _id           = nothing,
            modifiedCount = 0, 
            matchedCount  = 0,
            upsertedCount = 0,
        )
    end
    pipeline = Dict("\$set" => document)
    return update_one(collection, pipeline, query, options = options)
end

function update_one(collection::Mongoc.Collection, pipeline::String, query::Dict=Dict(); options = nothing)
    return update_one(collection, JSON.parse(pipeline), query, options = options)
end

function update_one(collection::Mongoc.Collection, pipeline::Dict, query::Dict=Dict(); options = nothing)
    if haskey(query, "_id") query["_id"] = bsonid(query["_id"]) end
    # --- Result
    result = Mongoc.update_one(
        collection, 
        Mongoc.BSON(query),
        Mongoc.BSON(pipeline),
        options = isnothing(options) ? Mongoc.BSON() : Mongoc.BSON(options)
    )
    return (
        _id           = haskey(query, "_id") ? string(query["_id"]) : query,
        modifiedCount = result["modifiedCount"], 
        matchedCount  = result["matchedCount"],
        upsertedCount = result["upsertedCount"]
    )
end

"""
    Updates many entries of the database.
    - document based: based on the query, sets all entries to the same document
    - dynamic pipeline: set your update pipeline and update entries based on the query.
"""
function update(collection::Mongoc.Collection, document::Mongoc.BSON, query::Dict=Dict(); options = nothing)
    pipeline = Dict("\$set" => document)
    return update(collection, pipeline, query, options = options)
end

function update(collection::Mongoc.Collection, pipeline::String, query::Dict=Dict(); options = nothing)
    return  update(collection, JSON.parse(pipeline), query, options = options)
end

function update(collection::Mongoc.Collection, pipeline::Dict, query::Dict=Dict(); options = nothing)
    if haskey(query, "_id") query["_id"] = bsonid(query["_id"]) end
    # --- Result
    result = Mongoc.update_many(
        collection, 
        Mongoc.BSON(query),
        Mongoc.BSON(pipeline),
        options = isnothing(options) ? Mongoc.BSON() : Mongoc.BSON(options)
    )
    return (
        modifiedCount = result["modifiedCount"], 
        matchedCount  = result["matchedCount"],
        upsertedCount = result["upsertedCount"]
    )
end

"""
    Delete data from the database.
    - delete: 
    Deletes data from the database based on the filter passed.
    Returns a Dict() with the number of objects deleted and the deleted objects
"""
function delete(collection::Mongoc.Collection, query::Dict=Dict(); options = nothing)
    if isempty(query) 
        @warn "delete: \nDidn't pass any filter to delete() and so it would have deleted all entries of the collection.\nPlease use drop() for this effect."
        return nothing
    end
    if haskey(query, "_id") query["_id"] = bsonid(query["_id"]) end
    result  = Mongoc.delete_many(
        collection, 
        Mongoc.BSON(query),
        options = isnothing(options) ? Mongoc.BSON() : Mongoc.BSON(options)
    )
    return (deletedCount = result["deletedCount"], )
end

function delete_one(collection::Mongoc.Collection, query::Dict=Dict(); options = nothing)
    if haskey(query, "_id") query["_id"] = bsonid(query["_id"]) end
    result  = Mongoc.delete_one(
        collection,
        Mongoc.BSON(query), 
        options = isnothing(options) ? Mongoc.BSON() : Mongoc.BSON(options)
    )
    return (deletedCount = result["deletedCount"], )
end

"""
    Deletes all entries from a collection
"""
function drop(collection::Mongoc.Collection)
    return Mongoc.drop(collection)
end

function aggregate(collection::Mongoc.Collection, pipeline::Union{Array, String})
    if typeof(pipeline) <: String
        pipeline = isempty(pipeline) ? [] : JSON.parse(pipeline)
    end
    query_flag    = Mongoc.QUERY_FLAG_NONE 
    query_options = Mongoc.BSON()

    pipeline_options = filter(x->haskey(x, "_options"), pipeline)
    if !isempty(pipeline_options)
        pipeline_options = first(pipeline_options)
        query_flag    = haskey(pipeline_options, "flag")    ? pipeline_options["flag"]    : query_flag
        query_options = haskey(pipeline_options, "options") ? pipeline_options["options"] : query_options
        pipeline = filter!(x->!haskey(x, "_options"), pipeline) # -- remove entry from pipeline (it doesn't make sense, it would cause an error)
    end
    
    return collect(
        Mongoc.aggregate(
            collection, 
            Mongoc.BSON(pipeline),
            flags   = query_flag,
            options = query_options
    ))
end

function count(collection::Mongoc.Collection, query::Dict=Dict(); options = nothing)
    if haskey(query, "_id") query["_id"] = bsonid(query["_id"]) end
    return Mongoc.count_documents(
        collection,
        Mongoc.BSON(query),
        options = isnothing(options) ? Mongoc.BSON() : Mongoc.BSON(options)
    )
end

function raw(db::Mongoc.Database, query)
    result = Mongoc.command_simple(
        db, 
        typeof(query) <: Array ?  Mongoc.BSON(query...) :  Mongoc.BSON(query)
    )
    return (values = result["values"], ok = result["ok"])
end
