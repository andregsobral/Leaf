# --- Relates the policy to the data and verifies the established conditions 
struct Validator
    policy     ::Dict{Symbol, Function}
    data       ::Dict
    schematype ::DataType
end
requirements(v::Validator) = collect(keys(v.policy))
Base.isempty(v::Validator) = isempty(v.policy)
# TODO: Not being used for anything, which options to overload by schematype?
# schema_type(v::Validator)  = v.schematype

function Validator(T::Type{<:Schema}; kwargs...)
    policy = DataPolicy(T)
    if isnothing(policy)
        policy = Dict{Symbol, Function}()
    end
    metadata = merge(schema_metadata(T), Dict(kwargs))
    return Validator(policy, metadata, T)
end

# --- Validation of a Schema struct
function isvalid(schema::T; metadata...) where T <: Schema
    # --- stores data policy and metadata
    policy = Validator(T ; metadata...)
    # --- Verify that each policy condition is ok
    for field in requirements(policy)
        val = getfield(schema, field)
        if !isvalid(policy, field, val)
            throw(ValidationException(field, val, T))
        end
    end
    # --- All conditions have passed, or there is nothing to check
    return true
end

# --- Validation of a field of a Schema struct
function isvalid(::Type{T}, field::Symbol, val; metadata...) ::Bool where T <: Schema
    # integrity checks
    # --- The field must be in the Schema
    if !(field in fieldnames(T)) 
        msg = "Invalid $T: Field '$field' is not a valid field name"
        throw(ValidationException(msg, field, val, T))
    end
    # --- The value type must match with the Schema field type
    if typeof(val) <: fieldtype(T, field) 
        msg = "Invalid $T.$field: $(typeof(val)) does not match the schema's corresponding field type '$(fieldtype(T, field))'"
        throw(ValidationException(msg, field, val, T)) 
    end
    # Policy check
    policy = Validator(T; metadata...) # --- stores data policy and metadata
    if isempty(policy) return true end # --- Nothing to check
    # Check policy for field validation
    if !isvalid(policy, f, val)
        throw(ValidationException(field, val, T))
    end
    return true
end

# --- Runs the validation for a specific field, if such validation is defined.
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
