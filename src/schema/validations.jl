# --- Relates the policy to the data and verifies the established conditions 
struct Validator
    policy ::Dict{Symbol, Function}
    data
    schematype ::DataType
end
requirements(v::Validator) = collect(keys(v.policy))
Base.isempty(v::Validator) = isempty(v.policy)
# TODO: Not being used for anything, which options to overload by schematype?
schema_type(v::Validator)  = v.schematype

function Validator(T::Type{<:Schema}; kwargs...)
    policy = DataPolicy(T)
    if isnothing(policy)
        policy = Dict{Symbol, Function}()
    end
    return Validator(policy, Dict(kwargs), T)
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
    policy = verifier.policy
    if haskey(policy, field)
        func = policy[field]
        return func(val, verifier.data)
    end
    # -- No verification needed
    return true
end
# --- Overloads for String format
isvalid(::Type{T}, field::String, val; metadata...) where T <: Schema = isvalid(T, Symbol(field), val; metadata...)
isvalid(verifier::Validator, field::String, val)    ::Bool            = isvalid(verifier, Symbol(field), val)
