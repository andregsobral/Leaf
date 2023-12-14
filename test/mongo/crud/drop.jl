@testset "drop  " begin
        
    println("========== Mongo: drop        ===========")
    coll = Leaf.collection(Company)
    mongo.drop(Company)
    @test !(coll in Leaf.collection_names(mongo))
    # --- dropping a second time sends a warning
    @test isnothing(mongo.drop(Company))
    @test isnothing(mongo.drop(NonExistentType))
    reset_data()
    coll = Leaf.collection(Company)
    drop(Company)
    @test !(coll in Leaf.collection_names(Leaf.globalconn()))
    reset_data()
end