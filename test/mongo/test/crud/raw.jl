@testset "raw  " begin
    println("========== Mongo: raw        ===========")
    
    # --- command_simple: distinct (various interfaces)
    result = mongo.raw(""" 
        { 
            "distinct": "companies", 
            "key":      "currency"
        } 
    """)
    input_unique = sort(unique(map(x->x.currency, dummy_companies)))
    [ @test result.values[i] ==  input_unique[i] for i in eachindex(input_unique) ]
    
    result = mongo.raw(["distinct"=> "companies", "key"=> "currency"])
    [ @test result.values[i] ==  input_unique[i] for i in eachindex(input_unique) ]
    
    result = mongo.raw(distinct = "companies", key = "currency")
    [ @test result.values[i] ==  input_unique[i] for i in eachindex(input_unique) ]
    
    # --- non-existent key
    result = mongo.raw(""" 
        { 
            "distinct": "companies", 
            "key":      "non-existent"
        } 
    """)
    @test isempty(result.values)

    # --- calls function without any command
    @test_throws Mongoc.BSONError mongo.raw()

    # ---- global conn

    # --- command_simple: distinct (various interfaces)
    result = raw(""" 
    { 
        "distinct": "companies", 
        "key":      "currency"
    } 
    """)
    input_unique = sort(unique(map(x->x.currency, dummy_companies)))
    [ @test result.values[i] ==  input_unique[i] for i in eachindex(input_unique) ]
    
    result = raw(["distinct"=> "companies", "key"=> "currency"])
    [ @test result.values[i] ==  input_unique[i] for i in eachindex(input_unique) ]
    
    result = raw(distinct = "companies", key = "currency")
    [ @test result.values[i] ==  input_unique[i] for i in eachindex(input_unique) ]
    
    # --- non-existent key
    result = raw(""" 
        { 
            "distinct": "companies", 
            "key":      "non-existent"
        } 
    """)
    @test isempty(result.values)

    # --- calls function without any command
    @test_throws Mongoc.BSONError raw()
end
