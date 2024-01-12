
@testset "schema: Definition" begin
    println("========== schema: Definition ===========")
    # House is not a Schema
    @test !Leaf.is_schema(h1)
    @test !Leaf.is_schema(h2)
    @test !Leaf.is_schema(House)
    # House has a schema
    @test Leaf.has_schema(House)
    @test Leaf.has_schema(h1)
    @test Leaf.has_schema(h2)
    
    # --- Convert to Schemas
    h1_schema = Leaf.schema(h1)
    h2_schema = Leaf.schema(h2)
    # HouseSchema is a Schema
    @test Leaf.is_schema(h1_schema)
    @test Leaf.is_schema(h2_schema)
    @test Leaf.is_schema(HouseSchema)
    # Schema has a schema
    @test !Leaf.has_schema(h1_schema)
    @test !Leaf.has_schema(HouseSchema)
end

@testset "schema: Validation" begin
    println("========== schema: Validation ===========")
    # --- configurations
    # - No Policy has been set for the schema, at the moment
    @test Leaf.schema_type(House) <: HouseSchema
    @test isnothing(Leaf.DataPolicy(HouseSchema))
    # - No Policy, nothing to verify
    @test Leaf.isvalid(h1_schema)
    @test Leaf.isvalid(h2_schema)
    # --- Let's set a basic verification
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => (fval, args)-> length(fval) > 5),
    )
    @test Leaf.isvalid(h1_schema)
    # --- Test an invalid schema
    try
        Leaf.isvalid(h2_schema)
        @test false # --- it should never reach this instruction. An exception should be thrown
    catch err
        @test typeof(err) <: Leaf.ValidationException
        print(err.msg)
        println("-------------")
        @test err.field  == :address
        @test err.val    == h2_schema.address
        @test err.schema == typeof(h2_schema)
    end

    # --- Let's update the verification to also rely on metadata conditions
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => ((fval, args)-> length(fval) > 5),
        :city    => ((fval, args)-> haskey(args, :cities)    ? fval in args[:cities]    : false),
        :country => ((fval, args)-> haskey(args, :countries) ? fval in args[:countries] : false),
    ))
    # no metadata passed
    try
        Leaf.isvalid(h1_schema)
        @test false # --- it should never reach this instruction. An exception should be thrown
    catch err
        @test typeof(err) <: Leaf.ValidationException
        println(err.msg)
        println("-------------")
        @test err.field  == :country
        @test err.val    == h1_schema.country
        @test err.schema == typeof(h1_schema)
    end

    # incomplete metadata passed (missing countries)
    try
        Leaf.isvalid(h1_schema, cities = ["Lisboa"])
        @test false # --- it should never reach this instruction. An exception should be thrown
    catch err
        @test typeof(err) <: Leaf.ValidationException
        println(err.msg)
        println("-------------")
        @test err.field  == :country
        @test err.val    == h1_schema.country
        @test err.schema == typeof(h1_schema)
    end

    # correct validation
    @test Leaf.isvalid(h1_schema,
        cities    = ["Lisboa", "Madrid", "Dublin"], 
        countries = ["PT", "ES", "IE"]
    )
    
    # --- Let's update to add some logging to policy
    function data_in_rage(T, field, datafield, val, args) ::Bool
        possible_vals = haskey(args, datafield) ? args[datafield] : []
        result = val in args[datafield]
        if result == false
            @warn "$T.$field: '$val' not in the correct field options: $possible_vals"
        end
        return result
    end
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => ((val, args) -> length(val) > 5),
        :city    => ((val, args) -> data_in_rage(HouseSchema, :city,    :cities,    val, args)),
        :country => ((val, args) -> data_in_rage(HouseSchema, :country, :countries, val, args)),
    ))

    # Schema field 'city' not in the policy city options
    try
        Leaf.isvalid(h1_schema, cities = ["Madrid", "Dublin"], countries = ["PT", "ES", "IE"])
        @test false # --- it should never reach this instruction. An exception should be thrown
    catch err
        @test typeof(err) <: Leaf.ValidationException
        println(err.msg)
        println("-------------")
        @test err.field  == :city
        @test err.val    == h1_schema.city
        @test err.schema == typeof(h1_schema)
    end

    # Schema field 'country' not in the policy city options
    try
        Leaf.isvalid(h1_schema, cities = ["Lisboa","Madrid", "Dublin"], countries = ["ES", "IE"])
        @test false # --- it should never reach this instruction. An exception should be thrown
    catch err
        @test typeof(err) <: Leaf.ValidationException
        println(err.msg)
        println("-------------")
        @test err.field  == :country
        @test err.val    == h1_schema.country
        @test err.schema == typeof(h1_schema)
    end
    # --- reset to empty policy
    Leaf.clear_policy!(HouseSchema)
end