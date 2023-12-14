# ---- id utils
isbsonid(id::Mongoc.BSONObjectId) = true
function isbsonid(id)
    try
        Mongoc.BSONObjectId(id)
        return true
    catch err
        return false
    end
end
bsonid(id)                      = isbsonid(id) ? Mongoc.BSONObjectId(id) : id
bsonid(id::Mongoc.BSONObjectId) = id

unfold!(d::Mongoc.BSON, field::String) = Mongoc.BSON(unfold!(Mongoc.as_dict(d), field))
unfold!(d::Dict,        field::String) = (haskey(d, field) && d[field] isa Dict ? ([d[key] = value for (key, value) in d[field]]; delete!(d, field)) : d)

