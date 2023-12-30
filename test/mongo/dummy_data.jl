
dummy_companies = [
    Company("PT01", "Petro, S.A.", "PT", "EUR", 1000, nothing, "COMP_PT"), 
    Company("PT02", "Petro, S.A.", "PT", "EUR", 2000, nothing, "COMP_PT"), 
    Company("PT03", "Petro, S.A.", "PT", "DOL", 3000, nothing, "COMP_EN"),
    Company("PT04", "Petro, S.A.", "PT", "EUR", 4000, nothing, "COMP_PT")
]

dummy_instances = [
    DataInstance("PT01", "2022-03", 1, true,  "EUR", "user001", Dates.now()),
    DataInstance("PT01", "2022-04", 1, false, "EUR", "user001", Dates.now()),
    DataInstance("PT01", "2022-05", 1, true,  "EUR", "user002", Dates.now()),
    DataInstance("PT01", "2022-06", 1, true,  "EUR", "user003", Dates.now())
]

dummy_houses = [
    House("HardRock Cafe", "Paris", "France"),
    House("RockAmRing", "Berlim", "Germany"),
    House("RockFest", "Amesterdam", "Holland")
]

dummy_attributes = [
    Attribute("1", Dict("address" => "Paris", "country" => "France")),
    Attribute("2", Dict("another" => "test")),
]

function cleanup_dummy_data(conn::Leaf.Connection)
    conn.drop(Company)
    conn.drop(DataInstance)
    conn.drop(House)
    conn.drop(Attribute)
end

function insert_dummy_data(conn::Leaf.Connection)
    Mongoc.insert_many(
        Leaf.collection(Leaf.db(conn), Company),
        Base.convert.(Mongoc.BSON, dummy_companies)
    )
    Mongoc.insert_many(
        Leaf.collection(Leaf.db(conn), DataInstance),
        Base.convert.(Mongoc.BSON, dummy_instances)
    )
    Mongoc.insert_many(
        Leaf.collection(Leaf.db(conn), House),
        Base.convert.(Mongoc.BSON, dummy_houses)
    )
    Mongoc.insert_many(
        Leaf.collection(Leaf.db(conn), Attribute),
        Base.convert.(Mongoc.BSON, dummy_attributes)
    )
end

function reset_data(operation::String="")
    println("-------------------------------------")
    if isempty(operation)
        @info "Making db consistent for testing...."
    else
        @info "restoring db context after \"$operation\" testing...."
    end
    
    try
        cleanup_dummy_data(mongo)
        @info "dropped collections"
    catch err
        @warn "error dropping collections"
        throw(err)
    end
    try
        insert_dummy_data(mongo)
        @info "inserted data"
    catch err
        @warn "error inserting data"
        throw(err)
    end

    @info "done."
end

