
@testset "schema: create" begin
    h = House("tiny", "Lisboa", "PT")

    println("========== schema: create ===========")
    # --- No policy has been defined for the HouseSchema
    Leaf.delete_policy!(House)
    @assert isnothing(Leaf.DataPolicy(HouseSchema)) "non empty policy on test input"
    
    # Creation without policy
    houses_count = mongo.count(House)
    result = mongo.create(House("tiny", "Lisboa", "PT"))
    @test typeof(result) <: NamedTuple && result.status.insertedCount == 1 # result says a house was added
    @test mongo.count(House) == houses_count + 1 # added one entry to houses collection
    
    # set policy
    houses_count = mongo.count(House)
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => (fval, args)-> length(fval) > 5),
    )
    # fails policy
    @test_throws Leaf.ValidationException mongo.create(House("tiny", "Lisboa", "PT"))
    try
        mongo.create(House("tiny", "Lisboa", "PT"))
        @test false
    catch err
        @test typeof(err) <: Leaf.ValidationException
        @test err.field == :address
        @test err.val == getfield(h, err.field)
        @test Leaf.DataPolicy(HouseSchema)[:address](err.val, Dict()) == false # call validation function with schema value
    end
    # No house was added to database
    @test houses_count == mongo.count(House)

    # Changed policy for h2 to pass
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => (fval, args)-> length(fval) > 3),
    )
    result = mongo.create(House("tiny", "Lisboa", "PT"))
    @test typeof(result) <: NamedTuple && result.status.insertedCount == 1
    @test mongo.count(House) == houses_count + 1 # added one entry to houses
    @test Leaf.DataPolicy(HouseSchema)[:address](Leaf.schema(House("tiny", "Lisboa", "PT")).address, Dict())
    
    houses_count = mongo.count(House)

    # ---- Sets policy which field validation depends on static metadata (args input arg)
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => (fval, args)-> fval in args[:valid_addresses]),
    )
    # ---- Sets metadata for that schema
    Leaf.schema_metadata(::Type{HouseSchema}) = Dict(
        :valid_addresses => ["Rua Jose de Alvalade", "Trinity College Dublin"]
    ) 
    # --- house address is not within the valid addresses (throws validation error)
    @test_throws Leaf.ValidationException mongo.create(House("tiny", "Lisboa", "PT"))
    # --- house address is within the valid addresses (and so it is created on the database)
    result = mongo.create(House("Rua Jose de Alvalade", "Lisboa", "PT"))
    @test typeof(result) <: NamedTuple && result.status.insertedCount == 1
    @test mongo.count(House) == houses_count + 1 # added one entry to houses
    @test Leaf.DataPolicy(HouseSchema)[:address](Leaf.schema(House("Rua Jose de Alvalade", "Lisboa", "PT")).address, Leaf.schema_metadata(HouseSchema))

    reset_data("create")
end