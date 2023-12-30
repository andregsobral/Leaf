@testset "count  " begin
    println("========== Mongo: count      ===========")
    result = mongo.count(Company)
    @test result == length(dummy_companies)

    repgroup = "COMP_PT"
    result = mongo.count(Company, repgroup = repgroup)
    @test result == length(mongo.find(Company, repgroup = repgroup))
    
    repgroup = "Non-existent"
    result = mongo.count(Company, repgroup = repgroup)
    @test result == 0

    # ---- global conn
    result = Leaf.count(Company)
    @test result == length(dummy_companies)

    repgroup = "COMP_PT"
    result = Leaf.count(Company, repgroup = repgroup)
    @test result == length(find(Company, repgroup = repgroup))
    
    repgroup = "Non-existent"
    result = Leaf.count(Company, repgroup = repgroup)
    @test result == 0
end