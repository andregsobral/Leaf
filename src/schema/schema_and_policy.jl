abstract type Schema end
function Base.convert(::Type{Mongoc.BSON}, schema::Schema)
    data = Dict(
        string(field) => getfield(schema, field) 
            for field in fieldnames(typeof(schema))
    )
    return Mongoc.BSON(data)
end
# --- Overload if a schema has been defined 
schema(x)      = nothing
schema_type(x) = nothing
# --- Logic Checkers
is_schema(x)   = typeof(x) <: Schema
has_schema(x)  = !isnothing(schema_type(x)) && is_schema(schema_type(x)) 

const _DATA_POLICIES_ = Dict{String, Dict}()
function policies()
    return _DATA_POLICIES_
end
# --- Modifiers: Create/Replace Policy (for the 3 different APIs, Dict, Array or kwargs)
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
# --- Modifiers: Delete Policy
function delete_policy!(T::Type{<:Schema})
    if policy_exists(T)
        schema_name = string(T)
        delete!(_DATA_POLICIES_, schema_name)
        return schema_name
    end
    return nothing
end

# --- Acessors
# Fetch data policy relates to a schema
function DataPolicy(T::Type{<:Schema}) :: Union{Dict, Nothing}
    return policy_exists(T) ? 
        _DATA_POLICIES_[string(T)] : 
        nothing
end
# Does the policy exist?
function policy_exists(T::Type{<:Schema}) ::Bool
    return haskey(_DATA_POLICIES_, string(T))
end
# Lists the requirements of a policy (the fields being tested)
function policy_requirements(T::Type{<:Schema}) ::Array
    policy = DataPolicy(T)
    return collect(keys(policy))
end
# Does the policy have the requirement 'x'?
function policy_has_requirement(T::Type{<:Schema}, field::Symbol) ::Bool
    policy = DataPolicy(T)
    return haskey(policy, field)
end
