abstract type AbstractSchema end
# --- Overload if a schema has been defined 
schema(x)      = nothing
schema_type(x) = nothing

struct Validator
    policy ::Dict{Symbol, Function}
    data

    function Validator(policy::Dict, data)
        return new(Dict(Symbol(k)=>v for (k,v) in policy), data)
    end
end

function DataPolicy(::Type{<:AbstractSchema})
    return Dict{Symbol, Function}()
end

function DataPolicy(x)
    stype = schema_type(x)
    return !isnothing(stype) && stype <: AbstractSchema ? 
        DataPolicy(stype) : 
        DataPolicy(AbstractSchema)
end

function Validator(T::Type{<:AbstractSchema}; kwargs...)
    return Validator(DataPolicy(T), Dict(kwargs))
end

function policy_verifier(v::Validator, field::Symbol)
    return haskey(v.policy, field) ? v.policy[field] : nothing
end

function isvalid(schema::T; metadata...) where T <: AbstractSchema
    policy = Validator(T ; metadata...)
    for f in fieldnames(T)
        val = getfield(schema, f)
        if !isvalid(policy, f, val)
            return false
        end
    end
    return true
end

function isvalid(::Type{T}, field::Symbol, val; metadata...) ::Bool where T <: AbstractSchema
    policy = Validator(T; metadata...)
    return isvalid(policy, f, val)
end

function isvalid(policy::Validator, field::Symbol, val) ::Bool
    validation_func = policy_verifier(policy, field)
    if !isnothing(validation_func)
        return validation_func(val, policy.data)
    end
    return true
end


struct Company
    name ::String
    address::String
end

struct CompanySchema <: AbstractSchema
    name ::String
    address::String
end
schema(x::Company)           = CompanySchema(x.name, x.address)
schema_type(::Type{Company}) = CompanySchema
DataPolicy(::Type{CompanySchema}) = Dict(
    :name    => ((x,y)-> (length(x) > 5)),
    :address => ((x,y)-> (length(x) > 5))
)

c  = Company("PwC PT", "Lisboa")
cs = schema(c)


