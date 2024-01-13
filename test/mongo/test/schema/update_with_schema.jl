
@testset "schema: update_one" begin
    println("========== schema: update ===========")
    h = House("update example", "Lisboa", "PT")
    # ---- find db ids
    house_bsons = Leaf.find(Leaf.collection(mongo, House), Dict(), options = Dict("projection" => Dict("_id"=>true)))[1]
    house_ids   = [string(b["_id"]) for b in house_bsons]
    house_id    = first(house_ids)
    # --- No policy has been defined for the HouseSchema
    Leaf.delete_policy!(House)
    @assert isnothing(Leaf.DataPolicy(HouseSchema)) "non empty policy on test input"
    
    # Update without policy
    houses_count = mongo.update_one(h, Dict("_id" => house_id))
    output_house = mongo.find_one(House, _id = house_id)
    @test output_house == h
    
    # set policy
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => (fval, args)-> length(fval) < 5),
    )
    # fails policy
    h = House("another update example", "Lisboa", "PT")
    @test_throws Leaf.ValidationException mongo.update_one(h, Dict("_id" => house_id))
    try
        mongo.update_one(h, Dict("_id" => house_id))
        @test false
    catch err
        @test typeof(err) <: Leaf.ValidationException
        @test err.field == :address
        @test err.val == getfield(h, err.field)
        @test Leaf.DataPolicy(HouseSchema)[:address](err.val, Dict()) == false # call validation function with schema value
    end
    # No house was added to database
    @test output_house == mongo.find_one(House, _id = house_id) && output_house != h
    
    # does not fails policy
    @test Leaf.policy_exists(House)
    h = House("ok", "Lisboa", "PT")
    houses_count = mongo.update_one(h, Dict("_id" => house_id))
    @test h == mongo.find_one(House, _id = house_id)

    # update_one with field non existent in schema
    @test_throws Leaf.ValidationException mongo.update_one(House, Dict("field-does-not-exist" => "change"), Dict("_id" => house_id))
    try
        mongo.update_one(House, Dict("field-does-not-exist" => "change"), Dict("_id" => house_id))
        @test false
    catch err
        @test typeof(err) <: Leaf.ValidationException
        @test err.field == Symbol("field-does-not-exist")
        @test err.val   == "change"
        println(err.msg)
    end

    # update_one with value that does not match type in schema
    @test_throws Leaf.ValidationException mongo.update_one(House, Dict("address" => 123), Dict("_id" => house_id))
    try
        mongo.update_one(House, Dict("address" => 123), Dict("_id" => house_id))
        @test false
    catch err
        @test typeof(err) <: Leaf.ValidationException
        @test err.field == :address
        @test err.val   == 123
        println(err.msg)
    end

    # TODO:
    
    # ok - update_one of subset of fields
    result = mongo.update_one(House, Dict("address" => "test", "country" => "IE"), Dict("_id" => house_id))
    @test result.modifiedCount == 1
    h = mongo.find_one(House, _id = house_id)
    @test h.address == "test" && h.country == "IE"

    # - nok update_one of subset of fields (do not satisfy policy)
    @test_throws Leaf.ValidationException mongo.update_one(House, 
        Dict("address" => "pretty long address", "country" => "IE"), 
        Dict("_id" => house_id)
    )
    try
        mongo.update_one(House, 
            Dict("address" => "pretty long address", "country" => "IE"), 
            Dict("_id" => house_id)
        )
        @test false
    catch err
        @test typeof(err) <: Leaf.ValidationException
        @test err.field == :address
        @test err.val   == "pretty long address"
        println(err.msg)
        @test Leaf.DataPolicy(HouseSchema)[err.field](err.val, Dict()) == false # call validation function with schema value
    end

    reset_data("update")
end