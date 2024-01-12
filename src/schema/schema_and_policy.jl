
# ==============================================
#   Schema
# ==============================================

abstract type Schema end

# --- Overload when defining a new schema subtype 
schema(x)      = nothing    # mandatory, converts domain object to schema subtype
schema_type(x) = nothing    # mandatory, the schema subtype associated to the object
schema_metadata(x) = Dict() # optional, depends on application

# --- Logic Checkers
function is_schema(::Type{T}) ::Bool where T 
    return T <: Schema # If the user passes a type directly
end
function has_schema(::Type{T}) ::Bool where T
    s_type = schema_type(T)
    return is_schema(s_type)
end

# If the user passes an object, calls the previous functions with the object type
is_schema(x)  ::Bool = is_schema(typeof(x))  
has_schema(x) ::Bool = has_schema(typeof(x))

# Automatic converter from Schema to BSON
function Base.convert(::Type{Mongoc.BSON}, schema::Schema)
    data = Dict(
        string(field) => getfield(schema, field) 
            for field in fieldnames(typeof(schema))
    )
    return Mongoc.BSON(data)
end

# ==============================================
#   Policy
# ==============================================

const _DATA_POLICIES_ = Dict{String, Dict}()
function policies()
    return _DATA_POLICIES_
end

# ==============================================
#   Policy: Acessors
#
# - Fetch data policy that relates to a schema
# - Does the policy exist for that schema?
# ==============================================

# Fetch data policy that relates to a schema
function DataPolicy(T::Type{<:Schema}) :: Union{Dict, Nothing}
    return policy_exists(T) ? 
        _DATA_POLICIES_[string(T)] : 
        nothing
end

# Does the policy exist?
function policy_exists(T::Type{<:Schema}) ::Bool
    return haskey(_DATA_POLICIES_, string(T))
end

# ==============================================
#   Policy: Modifiers
#
# - Create/Replace Policy (for the 3 different APIs, Dict, Array or kwargs)
# - Clear policy: Associates an empty policy to a schema type
# - Delete policy: Removes any associated policy to a schema type
# ==============================================

function DataPolicy!(T::Type{<:Schema}, policy::Dict)
    _DATA_POLICIES_[string(T)] = policy
    return _DATA_POLICIES_[string(T)]
end

function DataPolicy!(T::Type{<:Schema}, policy::Array)
    new_policy = Dict(first(p) => last(p) for p in policy)
    return DataPolicy!(T, new_policy)
end

function DataPolicy!(T::Type{<:Schema}; kwargs...)
    return DataPolicy!(T, Dict(kwargs))
end

function clear_policy!(T::Type{<:Schema})
    DataPolicy!(T, Dict())
end

function delete_policy!(T::Type{<:Schema})
    if policy_exists(T)
        schema_name = string(T)
        delete!(_DATA_POLICIES_, schema_name)
        return schema_name
    end
    return nothing
end

# ==============================================
#   Policy: Utils
#
# - Overloads for non-schema types
# ==============================================

delete_policy!(x)         = call_schema_type_api(x, delete_policy!)
clear_policy!(x)          = call_schema_type_api(x, clear_policy!)
policy_exists(x)          = call_schema_type_api(x, policy_exists)
DataPolicy(x)             = call_schema_type_api(x, DataPolicy)
DataPolicy!(x, policy)    = call_schema_type_api(x, DataPolicy!, policy)
DataPolicy!(x; kwargs...) = call_schema_type_api(x, DataPolicy! ;kwargs...)

function call_schema_type_api(x, func, args...; kwargs...)
    if has_schema(x) 
        return func(Leaf.schema_type(x), args...; kwargs...) 
    end
end
