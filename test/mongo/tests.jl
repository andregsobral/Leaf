using Mongoc

include("setup.jl")
include("utils.jl")

# --- Connection
# retrieve via ENV if available, useful for local testing
const DBHOST = get(ENV, "DBHOST", "localhost")
const DBPORT = haskey(ENV, "DBPORT") ? Base.parse(Int, ENV["DBPORT"]) : 27017
const DBNAME = get(ENV, "DBNAME", "leaf_testing")
mongo = Leaf.connect(:mongo, DBNAME, host=DBHOST, port=DBPORT)
@info "Mongo: Leaf testing database -> $(Leaf.connectionstring(mongo))"

include("dummy_data.jl")
reset_data()

@testset "CRUD Mongo" begin
    # --- Connection to assets
    include(joinpath("test", "connections.jl"))
    # --- CRUD operations
    include(joinpath("test", "crud", "find.jl"))
    include(joinpath("test", "crud", "create.jl"))
    include(joinpath("test", "crud", "delete.jl"))
    include(joinpath("test", "crud", "update.jl"))
    include(joinpath("test", "crud", "update_one.jl"))
    include(joinpath("test", "crud", "count.jl"))
    include(joinpath("test", "crud", "raw.jl"))
    include(joinpath("test", "crud", "drop.jl"))
    # --- Schema and CRUD operations with schema
    include(joinpath("test", "schema", "structs.jl"))
    include(joinpath("test", "schema", "policy.jl"))
    include(joinpath("test", "schema", "schema.jl"))
    include(joinpath("test", "schema", "create_with_schema.jl"))
    include(joinpath("test", "schema", "update_with_schema.jl"))
end
