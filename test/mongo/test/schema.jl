
struct HouseSchema <: Leaf.Schema
    address       :: String                           # "HardRock Cafe"
    city          :: String                           # "Paris"
    country       :: String                           # "France"
end
Leaf.schema(x::House)           = HouseSchema(x.address, x.city, x.country)
Leaf.schema_type(::Type{House}) = HouseSchema

@testset "schema: DataPolicy" begin
    println("========== schema: DataPolicy ===========")

    # --- No policy has been defined for the HouseSchema
    @test isnothing(Leaf.DataPolicy(HouseSchema))
    @test isnothing(Leaf.delete_policy!(HouseSchema))
    # defines new policy: using Dict interface
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => (fval, args)-> length(fval) > 5),
    )
    policy = Leaf.DataPolicy(HouseSchema)
    @test !isempty(policy) && haskey(policy, :address) && length(keys(policy)) == 1
    # --- reset policy
    Leaf.delete_policy!(HouseSchema)
    @test isnothing(Leaf.DataPolicy(HouseSchema))

    # defines new policy: using Array interface
    Leaf.DataPolicy!(HouseSchema, [
        :address => ((fval, args)-> length(fval) > 5),
        :city    => ((fval, args)-> haskey(args, :cities)    ? fval in args[:cities]    : false),
        :country => ((fval, args)-> haskey(args, :countries) ? fval in args[:countries] : false),
    ])
    policy = Leaf.DataPolicy(HouseSchema)
    @test !isempty(policy) && haskey(policy, :address) && haskey(policy, :city) && haskey(policy, :country) && length(keys(policy)) == 3

    # --- reset policy
    Leaf.delete_policy!(HouseSchema)
    @test isnothing(Leaf.DataPolicy(HouseSchema))

    # defines new policy: using kwargs interface
    Leaf.DataPolicy!(HouseSchema,
        address = ((fval, args)-> length(fval) > 5),
        city    = ((fval, args)-> haskey(args, :cities)    ? fval in args[:cities]    : false),
        country = ((fval, args)-> haskey(args, :countries) ? fval in args[:countries] : false),
    )
    policy = Leaf.DataPolicy(HouseSchema)
    @test !isempty(policy) && haskey(policy, :address) && haskey(policy, :city) && haskey(policy, :country) && length(keys(policy)) == 3
    
    # --- reset policy
    Leaf.delete_policy!(HouseSchema)
    @test isnothing(Leaf.DataPolicy(HouseSchema))
end


@testset "schema: creation and validation" begin
    println("========== schema: creation and validation ===========")
    # --- data
    h1 = House("Rua Manuel Ferreira de Andrade", "Lisboa", "PT")
    h2 = House("tiny", "Lisboa", "PT")
    # --- Convert to Schemas
    h1_schema = Leaf.schema(h1)
    h2_schema = Leaf.schema(h2)
    @test Leaf.is_schema(h1_schema)
    @test Leaf.is_schema(h2_schema)
    @test !Leaf.is_schema(h1)
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
    @test !Leaf.isvalid(h2_schema)
    # --- Let's update the verification to also rely on metadata conditions
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => ((fval, args)-> length(fval) > 5),
        :city    => ((fval, args)-> haskey(args, :cities)    ? fval in args[:cities]    : false),
        :country => ((fval, args)-> haskey(args, :countries) ? fval in args[:countries] : false),
    ))
    # no metadata passed
    @test !Leaf.isvalid(h1_schema)
    @test !Leaf.isvalid(h1_schema, cities = ["Lisboa"])
    # correct validation
    @test Leaf.isvalid(h1_schema, cities = ["Lisboa", "Madrid", "Dublin"], countries = ["PT", "ES", "IE"])
    
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
    @test !Leaf.isvalid(h1_schema, cities = ["Madrid", "Dublin"], countries = ["PT", "ES", "IE"])
    @test !Leaf.isvalid(h1_schema, cities = ["Lisboa","Madrid", "Dublin"], countries = ["ES", "IE"])
end