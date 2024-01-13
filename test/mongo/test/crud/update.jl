function pipeline_setter(field, val)
    return typeof(val) <: String ?
        """{"\$set": {"$field":"$val"}}""" :
        """{"\$set": {"$field": $val}}"""
end

@testset "update  " begin
    println("========== Mongo: update     ===========")
    # ----- modify 1 entry
    c = Company("PT01", "Petro, S.A.", "PT", "EUR", 2000, nothing, "COMP_PT")
    
    # update all entries
    new_capital = 4999
    new_data    = pipeline_setter("capital", new_capital)
    result      = mongo.update(Company, new_data)
    entries     = mongo.find(Company)
    len_entries = length(entries)
    @test result.modifiedCount == len_entries && result.matchedCount  == len_entries && result.upsertedCount == 0
    [@test c.capital == new_capital for c in entries]

    # nothing to update
    result = mongo.update(Company, new_data)
    @test result.modifiedCount == 0 && result.matchedCount  == len_entries && result.upsertedCount == 0
    
    # update subset of entries
    subset_len = length(mongo.find(Company, currency = "EUR"))
    new_currency = "Another"
    new_data    = pipeline_setter("currency", new_currency)
    result     = mongo.update(Company, new_data, currency = "EUR")
    entries    = mongo.find(Company, currency = new_currency)
    
    @test subset_len < len_entries
    @test result.modifiedCount == subset_len && result.matchedCount  == subset_len && result.upsertedCount == 0
    [@test c.currency == new_currency for c in entries]

    # trying to update an "_id" field
    @test_throws Mongoc.BSONError mongo.update(Company, Dict("\$set" => Dict("_id" => "Another")), _id = "PT01")
    
    # ---- Make database consistent
    reset_data("update")

    # ------------- global conn
    new_capital = 4999
    new_data    = pipeline_setter("capital", new_capital)
    result      = update(Company, new_data)
    entries     = find(Company)
    len_entries = length(entries)
    @test result.modifiedCount == len_entries && result.matchedCount  == len_entries && result.upsertedCount == 0
    [@test c.capital == new_capital for c in entries]

    # nothing to update
    result = update(Company, new_data)
    @test result.modifiedCount == 0 && result.matchedCount  == len_entries && result.upsertedCount == 0
        
    # update subset of entries
    subset_len = length(find(Company, currency = "EUR"))
    new_currency = "Another"
    new_data    = pipeline_setter("currency", new_currency)
    result     = update(Company, new_data, currency = "EUR")
    entries    = find(Company, currency = new_currency)
        
    @test subset_len < len_entries
    @test result.modifiedCount == subset_len && result.matchedCount  == subset_len && result.upsertedCount == 0
    [@test c.currency == new_currency for c in entries]

    # trying to update an "_id" field
    @test_throws Mongoc.BSONError update(Company, Dict("\$set" => Dict("_id" => "Another")), _id = "PT01")
    
    # ---- Make database consistent
    reset_data("update")
end
