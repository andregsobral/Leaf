@testset "delete  " begin
    println("========== Mongo: delete     ===========")
    # ----- delete all entries
    result = mongo.delete(Company)
    @test isnothing(result)                                      # ---- blind delete guard
    @test length(mongo.find(Company)) == length(dummy_companies) # ---- no delete should have been made
    
    # --- delete multiple entries based on a filter
    result = mongo.delete(Company, currency = "EUR")
    @test result.deletedCount == 3

    # --- delete one entry
    result = mongo.delete_one(Company, _id = "PT03")
    @test result.deletedCount == 1

    # --- delete non existant entry
    result = mongo.delete_one(Company, currency = "EUR")
    @test result.deletedCount == 0 # -- it doesn't exist

    # ---- Make database consistent
    reset_data("delete")

    # ----- delete all entries - globalconn
    result = delete(Company)
    @test isnothing(result)                                # ---- blind delete guard
    @test length(find(Company)) == length(dummy_companies) # ---- no delete should have been made
    # --- delete multiple entries based on a filter
    result = delete(Company, currency = "EUR")
    @test result.deletedCount == 3

    # --- delete one entry
    result = delete_one(Company, _id = "PT03")
    @test result.deletedCount == 1

    # --- delete non existant entry
    result = delete_one(Company, currency = "EUR")
    @test result.deletedCount == 0 # -- it doesn't exist

    # ---- Make database consistent
    reset_data("delete")
end