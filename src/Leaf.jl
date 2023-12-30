module Leaf

# --- Available Generic CRUD methods
export find,   find_one
export update, update_one
export create
export delete, delete_one
export drop, aggregate, raw

abstract type Database end
abstract type RelationalDB <: Database end
abstract type NoSQLDB      <: Database end

# --- Override for each Database type
data_format(::Type{T}) where T <: Database  = @warn("Generic method to select the data format of yout database. Please implement for your Database Type") 
collection(db::Database, ::Type{T}) where T = @warn("Generic method to get a database collection. Please implement for your Database Type.")

# ---- Overrides for business layer objects
collection(::Type{T}) where T               = @warn("Generic method to get a database collection from a business object type.\nPlease implement \"Leaf.collection(::Type{YourType}) = .....\" for your business layer types.")        
# --- Override for each type for data validation to occur on create and update.
function validate(x) ::Bool return true end 

# ---- CRUD
include("exceptions.jl")   # ---- Runtime expections
include("connections.jl")  # ---- Database Connections API
include("generic_crud.jl") # ---- Generic CRUD API 

# ---- Specific Database implemententations
include("databases/mongo.jl") # ---- Mongo

end # module
