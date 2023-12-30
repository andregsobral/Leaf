@testset "create  " begin
    println("========== Mongo: create     ===========")
    # ----- single create
    c = Company("PT10000", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
    result = mongo.create(c)
    @test result.status.insertedCount == 1
    @test result._id                  == c._id
    @test length(mongo.find(Company)) == length(dummy_companies) + 1
    # --- duplicate entry
    @test_throws Mongoc.BSONError mongo.create(c)

    # ----- global conn - single create
    c = Company("PT10011", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
    result = create(c)
    @test result.status.insertedCount == 1
    @test result._id                  == c._id
    @test length(find(Company)) == length(dummy_companies) + 2
    # --- duplicate entry
    @test_throws Mongoc.BSONError create(c)

    # ----- multiple create
    multiple = [
        Company("PT10001", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
        Company("PT10002", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
        Company("PT10003", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
    ]
    result = mongo.create(multiple)
    @test result.status.insertedCount == length(multiple)
    @test result._id isa Array
    [ @test multiple[i]._id == result._id[i] for i in eachindex(multiple) ]
    # --- duplicate entry
    @test_throws Mongoc.BSONError mongo.create(Company("PT10001", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT"))
    
    # ----- multiple create - global conn
    multiple = [
        Company("PT10021", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
        Company("PT10022", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
        Company("PT10023", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT")
    ]
    result = create(multiple)
    @test result.status.insertedCount == length(multiple)
    @test result._id isa Array
    [ @test multiple[i]._id == result._id[i] for i in eachindex(multiple) ]
    # --- duplicate entry
    @test_throws Mongoc.BSONError create(Company("PT10021", "Petro, S.A.", "PT", "EUR", 10000, nothing, "COMP_PT"))
    
    # ---- Make database consistent
    reset_data("create")
end