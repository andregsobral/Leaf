abstract type Schema end
# --- Overload if a schema has been defined 
schema(x)      = nothing
schema_type(x) = nothing
is_schema(x)   = typeof(x) <: Schema

const _DATA_POLICIES_ = Dict{String, Dict}()
function policies()
    return _DATA_POLICIES_
end
# --- Modifiers: Policy
function DataPolicy!(T::Type{<:Schema}, policy::Dict)
    _DATA_POLICIES_[string(T)] = policy
    return _DATA_POLICIES_[string(T)]
end
function DataPolicy!(T::Type{<:Schema}, policy::Array)
    new_policy = Dict(first(p) => last(p) for p in policy)
    return DataPolicy!(T, new_policy)
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

# TODO: Leave these modifiers or are they irrelevant?

# # --- Modifiers: Requirement
# function create_requirement!(T::Type{<:Schema}, field::Symbol, func)
#     if policy_exists(T)
#         schema_name = string(T)
#         _DATA_POLICIES_[schema_name][field] = func
#     end
# end

# # create new, if one does not exist already)
# function add_requirement(T::Type{<:Schema}, field::Symbol, func)
#     if !policy_has_requirement(T, field)
#         create_requirement!(T, field, func)        
#     end
# end
# # replaces existing requirement
# function replace_requirement(T::Type{<:Schema}, field::Symbol, requirement::Function)
#     if policy_has_requirement(T, field)
#         create_requirement!(T, field, func)
#     end
# end
# # deletes requirement
# function delete_requirement(T::Type{<:Schema}, field::Symbol, requirement::Function)
#     if policy_has_requirement(T, field)
#         delete!(_DATA_POLICIES_[schema_name], field)
#     end
# end
