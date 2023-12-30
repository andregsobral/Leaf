@testset "conn creation" begin
    # ToDo: test connection creation
end

@testset "globalconn    " begin
    println("========== Mongo: globalconn ===========")
    @test typeof(Leaf.DBCONN) <: Ref
    @test isnothing(Leaf.globalconn())
    Leaf.globalconn!(mongo)
    @test typeof(Leaf.globalconn()) <: Leaf.Connection
    @test Leaf.globalconn() == Leaf.DBCONN[]
    @test mongo == Leaf.DBCONN[]
end

