@testset "update_one  " begin
    println("========== Mongo: update_one     ===========")

    id = "PT01"
    c = Company(id, "Petro, S.A.", "PT", "EUR", 2000, nothing, "COMP_PT")
    pipeline_setter = ((x,y) -> Dict("\$set" => Dict(x => y)))

    # ----- modify 1 entry
    result = mongo.update_one(c)
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0 && result._id  == id
    @test c == mongo.find_one(Company, _id = id)

    # ----- modify 1 entry (not the first entry of the collection)
    id = "PT03"
    c = Company(id, "Petro, S.A.", "PT", "DOL", 3001, nothing, "COMP_EN")
    result = mongo.update_one(c)
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0 && result._id  == id
    @test c == mongo.find_one(Company, _id = id)

    # ----- Unable to modify entry if query is not specified (struct does not have _id field)
    h = House("HardRock Cafe", "Marseille", "France")
    result = mongo.update_one(h)
    @test result.modifiedCount == 0 && result.matchedCount  == 0 && result.upsertedCount == 0 && isnothing(result._id)

    # ----- Must specify query
    result = mongo.update_one(h, address = "HardRock Cafe")
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0 && result._id  == Dict("address" => "HardRock Cafe")
    @test h == mongo.find_one(House, address = "HardRock Cafe")


    # ---- Try to modify again without changes, nothing to modify
    result = mongo.update_one(c)
    @test result.modifiedCount == 0 && result.matchedCount  == 1

    # ----- modify 1 entry, using another interface
    pipeline_setter = ((x,y) -> Dict("\$set" => Dict(x => y)))
    new_capital = 3000
    new_data    = pipeline_setter("capital", new_capital)
    result = mongo.update_one(Company, new_data, Dict("_id" => "PT01"))
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0
    @test mongo.find_one(Company, _id = "PT01").capital == new_capital

    new_capital = 3001
    new_data    = pipeline_setter("capital", new_capital)
    result = mongo.update_one(Company, new_data, """{ "_id": "PT01" }""")
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0
    @test mongo.find_one(Company, _id = "PT01").capital == new_capital

    new_capital = 3002
    new_data    = pipeline_setter("capital", new_capital)
    result = mongo.update_one(Company, new_data, _id = "PT01")
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0
    @test mongo.find_one(Company, _id = "PT01").capital == new_capital
    
    result = mongo.update_one(Attribute, 
        """{"\$unset" : {"attrs.address": ""}}""",
        name = "1" 
    )
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0

    result = mongo.update_one(Attribute, 
        Dict("\$unset" => Dict("attrs.address" => "")),
        name = "1" 
    )
    @test result.modifiedCount == 0 && result.matchedCount  == 1 && result.upsertedCount == 0

    result = mongo.update_one(Attribute, Dict("\$unset" => Dict("attrs.address" => "")))
    @test result.modifiedCount == 0 && result.matchedCount  == 1 && result.upsertedCount == 0

    result = mongo.update_one(Attribute, """{"\$unset" : {"attrs.address": ""}}""")
    @test result.modifiedCount == 0 && result.matchedCount  == 1 && result.upsertedCount == 0
    
    @test length(keys(mongo.find_one(Attribute, name = "1").attrs)) == 1
    
    # ---- Make database consistent
    reset_data("update")

    # ------------- global conn
    # ----- modify 1 entry
    c = Company("PT01", "Petro, S.A.", "PT", "EUR", 2000, nothing, "COMP_PT")
    result = update_one(c)
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0
    @test c == find_one(Company, _id = "PT01")

    # ---- Try to modify again without changes, nothing to modify
    result = update_one(c)
    @test result.modifiedCount == 0 && result.matchedCount  == 1

    # ----- modify 1 entry, using another interface
    new_capital = 3000
    new_data    = pipeline_setter("capital", new_capital)
    result = update_one(Company, new_data, Dict("_id" => "PT01"))
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0
    @test find_one(Company, _id = "PT01").capital == new_capital

    new_capital = 3001
    new_data    = pipeline_setter("capital", new_capital)
    result = update_one(Company, new_data, """{ "_id": "PT01" }""")
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0
    @test find_one(Company, _id = "PT01").capital == new_capital

    new_capital = 3002
    new_data    = pipeline_setter("capital", new_capital)
    result = update_one(Company, new_data, _id = "PT01")
    @test result.modifiedCount == 1 && result.matchedCount  == 1 && result.upsertedCount == 0
    @test find_one(Company, _id = "PT01").capital == new_capital
    
    # ---- Make database consistent
    reset_data("update")
end
