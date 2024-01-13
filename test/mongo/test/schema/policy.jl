
@testset "schema: DataPolicy" begin
    println("========== schema: DataPolicy ===========")
    # --- No policy has been defined for the HouseSchema
    @test isnothing(Leaf.DataPolicy(HouseSchema))
    @test isnothing(Leaf.delete_policy!(HouseSchema))
    # -------
    
    # Defines new policy: using Dict interface
    Leaf.DataPolicy!(HouseSchema, Dict(
        :address => (fval, args)-> length(fval) > 5),
    )
    policy = Leaf.DataPolicy(HouseSchema)
    @test !isempty(policy) && haskey(policy, :address) && length(keys(policy)) == 1

    # Defines new policy: using Array interface
    Leaf.DataPolicy!(HouseSchema, [
        :address => ((fval, args)-> length(fval) > 5),
        :city    => ((fval, args)-> haskey(args, :cities)    ? fval in args[:cities]    : false),
        :country => ((fval, args)-> haskey(args, :countries) ? fval in args[:countries] : false),
    ])
    policy = Leaf.DataPolicy(HouseSchema)
    @test !isempty(policy) && haskey(policy, :address) && haskey(policy, :city) && haskey(policy, :country) && length(keys(policy)) == 3

    # Defines new policy: using kwargs interface
    Leaf.DataPolicy!(HouseSchema,
        address = ((fval, args)-> length(fval) > 5),
        city    = ((fval, args)-> haskey(args, :cities)    ? fval in args[:cities]    : false),
        country = ((fval, args)-> haskey(args, :countries) ? fval in args[:countries] : false),
    )
    policy = Leaf.DataPolicy(HouseSchema)
    @test !isempty(policy) && haskey(policy, :address) && haskey(policy, :city) && haskey(policy, :country) && length(keys(policy)) == 3
    
    # --- clear policy
    Leaf.clear_policy!(HouseSchema)
    @test isempty(Leaf.DataPolicy(HouseSchema))
    
    # --- delete policy
    Leaf.delete_policy!(HouseSchema)
    @test isnothing(Leaf.DataPolicy(HouseSchema))
end

