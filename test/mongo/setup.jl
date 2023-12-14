abstract type NonExistentType end
Leaf.collection(::Type{NonExistentType}) = "non-existent"

Leaf.collection(::Type{Company})      = "companies"
Leaf.collection(::Type{DataInstance}) = "instances"
Leaf.collection(::Type{House})        = "houses"
Leaf.collection(::Type{Attribute})    = "attributes"

function Base.convert(::Type{Mongoc.BSON}, c::Company)
    return Mongoc.BSON(
        "_id"      => c._id,
        "name"     => c.name,
        "country"  => c.country,
        "currency" => c.currency,
        "capital"  => c.capital,
        "unit"     => c.unit,
        "repgroup" => c.repgroup
    )
end

function Base.convert(::Type{Mongoc.BSON}, d::DataInstance)
    return Mongoc.BSON(
        "_id"        => Dict("company" => d.company, "period" => d.period, "version" => d.version),
        "active"     => d.active,
        "currency"   => d.currency,
        "created_by" => d.created_by,
        "created_at" => d.created_at
    )
end

function Base.convert(::Type{Mongoc.BSON}, d::House)
    return Mongoc.BSON(
        "address" => d.address,
        "city"    => d.city,
        "country" => d.country,
    )
end

function Base.convert(::Type{Mongoc.BSON}, c::Attribute)
    return Mongoc.BSON(
        "name"   => c.name,
        "attrs"  => c.attrs,
    )
end


function Base.convert(::Type{Company}, document::Mongoc.BSON)
    return Company(
        document["_id"], 
        document["name"], 
        document["country"],
        document["currency"],
        document["capital"],
        document["unit"],
        document["repgroup"]
    )
end

function Base.convert(::Type{DataInstance}, document::Mongoc.BSON)
    return DataInstance(
        document["_id"]["company"], 
        document["_id"]["period"],
        document["_id"]["version"],
        document["active"], 
        document["currency"], 
        document["created_by"], 
        document["created_at"]
    )
end

function Base.convert(::Type{House}, document::Mongoc.BSON)
    return House(
        document["address"],
        document["city"],
        document["country"],
    )
end

function Base.convert(::Type{Attribute}, c::Mongoc.BSON)
    return Attribute(
        c["name"],
        c["attrs"]
    )
end
