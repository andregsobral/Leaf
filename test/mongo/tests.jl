using Mongoc

include("setup.jl")
include("utils.jl")

# --- Connection
# retrieve via ENV if available, useful for local testing
const DBHOST = get(ENV, "DBHOST", "mongo")
const DBPORT = haskey(ENV, "DBPORT") ? Base.parse(Int, ENV["DBPORT"]) : 27017
const DBNAME = get(ENV, "DBNAME", "leaf_testing")
mongo = Leaf.connect(:mongo, DBHOST, DBNAME, port=DBPORT)
@info "Mongo: Leaf testing database -> $DBHOST:$DBPORT[\"$DBNAME\"]"

include("dummy_data.jl")

@testset "CRUD Mongo" begin

    @testset "globalconn    " begin
        println("========== Mongo: globalconn ===========")
        @test typeof(Leaf.DBCONN) <: Ref
        @test isnothing(Leaf.globalconn())
        Leaf.globalconn!(mongo)
        @test typeof(Leaf.globalconn()) <: Leaf.Connection
        @test Leaf.globalconn() == Leaf.DBCONN[]
        @test mongo == Leaf.DBCONN[]
    end

    include(joinpath("crud", "find.jl"))
    include(joinpath("crud", "create.jl"))
    include(joinpath("crud", "delete.jl"))
    include(joinpath("crud", "update.jl"))
    include(joinpath("crud", "update_one.jl"))
    include(joinpath("crud", "count.jl"))
    include(joinpath("crud", "raw.jl"))
    include(joinpath("crud", "drop.jl"))
end
