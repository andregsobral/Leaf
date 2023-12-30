@testset "find    " begin
    println("========== Mongo: find       ===========")
    crud_function = find

    # ----- find companies
    res = collect_interfaces_data(Company, crud_function)
    # ---- test
    test_return_type(Array, res)
    test_each_item_length(res, 4)
    test_identical_data(res, crud_function, test_data_item = dummy_companies)
   
    # ----- single filter: different query interfaces
    
    # -- Filters
    fkwargs  = [:repgroup => "COMP_PT"]
    dictargs = Dict("repgroup" => "COMP_PT")
    sargs    = """ { "repgroup": "COMP_PT" }"""
    res = collect_interfaces_data(Company, crud_function, fkwargs, dictargs, sargs)
    # ---- test
    test_return_type(Array, res)
    test_each_item_length(res, 3)
    test_identical_data(res, crud_function)

    # ----- multi filter: different query interfaces
    op = "\$gte"
    # -- Filters
    fkwargs  = [:repgroup => "COMP_PT", :country => "PT", :capital => Dict(op => 2000)]
    dictargs = Dict("repgroup"=> "COMP_PT", "country"  => "PT", "capital"  => Dict(op => 2000))
    sargs    = """ { "repgroup": "COMP_PT", "country" : "PT", "capital" : {\"$op\": 2000 } } """
    # -- Collect data
    res = collect_interfaces_data(Company, crud_function, fkwargs, dictargs, sargs)
    # ---- test
    test_return_type(Array, res)
    test_each_item_length(res, 2)
    test_identical_data(res, find)

    # ----- projection: different query interfaces
    # -- Collect data
    res1 = mongo.find(Company, repgroup = "COMP_PT", country = "PT", _options = """{"projection": {"repgroup": true}}""")
    res2 = mongo.find(Company, Dict("repgroup"=> "COMP_PT", "country"  => "PT"),  options = Dict("projection" => Dict("repgroup" => true)))
    res3 = mongo.find(Company, """{ "repgroup": "COMP_PT", "country" : "PT" }""", options = """{"projection": {"repgroup": true}} """)
    @test typeof(res1) <: Vector{Mongoc.BSON} && typeof(res2) <: Vector{Mongoc.BSON} && typeof(res3) <: Vector{Mongoc.BSON}
    @test length(res1) == 3 && length(res2) == 3 && length(res3) == 3
    @test res1 == res2 && res2 == res3
    for vec in [res1,res2,res3]
        for item in vec
            item_d = Mongoc.as_dict(item)
            @test length(keys(item_d)) == 2
            @test haskey(item_d, "repgroup") && haskey(item_d, "_id")
        end
    end
    
    # ----- find instances
    res = collect_interfaces_data(DataInstance, crud_function)
    # ---- test
    test_return_type(Array, res)
    test_each_item_length(res, 4)
    test_identical_data(res, crud_function, test_data_item = dummy_instances)
end

@testset "find_one" begin
    println("========== Mongo: find_one   ===========")
    crud_function = find_one

    # ----- find_one companies
    res = collect_interfaces_data(Company, crud_function)
    # ---- test
    test_return_type(Company, res)
    test_identical_data(res, crud_function, test_data_item = first(dummy_companies))

    # -- Single Filters
    fkwargs  = [:repgroup => "COMP_PT"]
    dictargs = Dict("repgroup"=> "COMP_PT")
    sargs    = """ { "repgroup": "COMP_PT" } """
    # -- Collect data
    res = collect_interfaces_data(Company, crud_function, fkwargs, dictargs, sargs)
    # ---- test
    test_return_type(Company, res)
    test_identical_data(res, crud_function)

    # -- Multiple Filters
    fkwargs  = [:repgroup => "COMP_PT", :capital => 1000]
    dictargs = Dict("repgroup"=> "COMP_PT", "capital" => 1000)
    sargs    = """ { "repgroup": "COMP_PT", "capital": 1000} """
    # -- Collect data
    res = collect_interfaces_data(Company, crud_function, fkwargs, dictargs, sargs)
    # ---- test
    test_return_type(Company, res)
    test_identical_data(res, crud_function)

    # -- Find by _id
    # -- Multiple Filters
    fkwargs  = [:_id => "PT01"]
    dictargs = Dict("_id" => "PT01")
    sargs    = """ { "_id": "PT01" } """
    # -- Collect data
    res = collect_interfaces_data(Company, crud_function, fkwargs, dictargs, sargs)
    test_return_type(Company, res)
    test_identical_data(res, crud_function)


    # ----- find instances
    res = collect_interfaces_data(DataInstance, crud_function)
    # ---- test
    test_return_type(DataInstance, res)
    test_identical_data(res, crud_function, test_data_item = first(dummy_instances))

    # -- Find by composite _id
    sample_id = Dict("period" => "2022-03", "company" => "PT01", "version" => 1)
    fkwargs  = [    :_id  => sample_id]
    dictargs = Dict("_id" => sample_id)
    sargs    = """{ "_id": { "period": "2022-03",  "company": "PT01", "version": 1} }"""
    # -- Collect data
    res = collect_interfaces_data(DataInstance, crud_function, fkwargs, dictargs, sargs)
    test_return_type(DataInstance, res)
    test_identical_data(res, crud_function)

    # ---- Empty find_one query (wrong collection)
    res = collect_interfaces_data(Company, crud_function, fkwargs, dictargs, sargs)
    test_return_type(Nothing, res)
    
    # -- Find by MongoBSONObjectId _id
    bson_data   = Mongoc.find_one(Leaf.collection(Leaf.db(mongo), House), Mongoc.BSON())
    bson_struct = Base.convert(House, bson_data)
    # ---- string object id
    bson_id  = string(bson_data["_id"])
    fkwargs  = [    :_id  => bson_id]
    dictargs = Dict("_id" => bson_id)
    sargs    = """{ "_id":  "$bson_id" }"""
    # ---- find_ones
    @test mongo.find_one(House; fkwargs...) == bson_struct
    @test mongo.find_one(House, sargs)      == bson_struct
    @test mongo.find_one(House, dictargs)   == bson_struct
    @test find_one(House; fkwargs...)       == bson_struct
    @test find_one(House, sargs)            == bson_struct
    @test find_one(House, dictargs)         == bson_struct

    # -- Find by MongoBSONObjectId _id
    bson_id  = bson_data["_id"]
    fkwargs  = [    :_id  => bson_id]
    dictargs = Dict("_id" => bson_id)
    # ---- find_ones
    @test mongo.find_one(House; fkwargs...) == bson_struct
    @test mongo.find_one(House, dictargs)   == bson_struct
    @test find_one(House; fkwargs...)       == bson_struct
    @test find_one(House, dictargs)         == bson_struct
    @test_throws ErrorException mongo.find_one(House, """{ "_id":  "$bson_id" }""")
    @test_throws ErrorException       find_one(House, """{ "_id":  "$bson_id" }""")

    # ----- projection: different query interfaces
    # -- Collect data
    res1 = mongo.find_one(Company, repgroup = "COMP_PT", country = "PT",              _options = """{"projection": {"repgroup": true}}""")
    res2 = mongo.find_one(Company, Dict("repgroup"=> "COMP_PT", "country"  => "PT"),  options  = Dict("projection" => Dict("repgroup" => true)))
    res3 = mongo.find_one(Company, """{ "repgroup": "COMP_PT", "country" : "PT" }""", options  = """{"projection": {"repgroup": true}} """)
    @test typeof(res1) <: Mongoc.BSON && typeof(res2) <: Mongoc.BSON && typeof(res3) <: Mongoc.BSON
    @test res1 == res2 && res2 == res3
    for item in [res1,res2,res3]
        item_d = Mongoc.as_dict(item)
        @test length(keys(item_d)) == 2
        @test haskey(item_d, "repgroup") && haskey(item_d, "_id")
    end
end
