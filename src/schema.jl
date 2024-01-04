abstract type Schema end
# --- Overload if a schema has been defined 
schema(x)      = nothing
schema_type(x) = nothing
is_schema(x)   = typeof(x) <: Schema 

function DataPolicy(::Type{<:Schema})
    return Dict{Symbol, Function}()
end

function DataPolicy(x)
    stype = schema_type(x)
    return !isnothing(stype) && stype <: Schema ? 
        DataPolicy(stype) : 
        DataPolicy(Schema)
end

# --- Relates the policy to the data and verifies the established conditions 
struct Validator
    policy ::Dict{Symbol, Function}
    data
    Validator(policy::Dict,  data) = new(Dict(Symbol(k)=>v for (k,v) in policy),  data)
    Validator(policy::Array, data) = new(Dict(first(p)=>last(p) for p in policy), data)
end
requirements(v::Validator) = collect(keys(policy(v)))
policy(v::Validator)       = v.policy
policy_data(v::Validator)  = v.data
Base.isempty(v::Validator) = isempty(v.policy)

function Validator(T::Type{<:Schema}; kwargs...)
    return Validator(DataPolicy(T), Dict(kwargs))
end

function isvalid(schema::T; metadata...) where T <: Schema
    # --- stores data policy and metadata
    policy = Validator(T ; metadata...)
    # --- Verify that each policy condition is ok
    for field in requirements(policy)
        val = getfield(schema, field)
        if !isvalid(policy, field, val)
            return false
        end
    end
    # --- All conditions have passed, or there is nothing to check
    return true
end

function isvalid(::Type{T}, field::Symbol, val; metadata...) ::Bool where T <: Schema
    policy = Validator(T; metadata...) # --- stores data policy and metadata
    if isempty(policy) return true end # --- Nothing to check
    return isvalid(policy, f, val)
end

function isvalid(verifier::Validator, field::Symbol, val) ::Bool
    # -- Field is subject to some verification
    policy = policy(verifier)
    if haskey(policy, field)
        func = policy[field]
        return func(val, policy_data(policy))    
    end
    # -- No verification needed
    return true
end
# --- Overloads for String format
isvalid(::Type{T}, field::String, val; metadata...) where T <: Schema = isvalid(T, Symbol(field), val; metadata...)
isvalid(verifier::Validator, field::String, val)    ::Bool            = isvalid(verifier, Symbol(field), val)
