@testset "conn creation" begin
    # Simple URI
    conn = Leaf.connect(:mongo, DBNAME, "mongodb://$DBHOST:$DBPORT")
    @test Leaf.dbname(conn) == DBNAME
    @test Leaf.host(conn)   == DBHOST
    @test Leaf.port(conn)   == DBPORT
    @test Leaf.connectionstring(conn) == "mongodb://$DBHOST:$DBPORT"
    @test isnothing(Leaf.username(conn))
    @test isnothing(Leaf.password(conn))
    @test isnothing(Leaf.authMechanism(conn))
    @test isnothing(Leaf.authSource(conn))
    
    conn = Leaf.connect(:mongo, DBNAME, host=DBHOST, port=DBPORT)
    @test Leaf.dbname(conn) == DBNAME
    @test Leaf.host(conn)   == DBHOST
    @test Leaf.port(conn)   == DBPORT
    @test Leaf.connectionstring(conn) == "mongodb://$DBHOST:$DBPORT"
    @test isnothing(Leaf.username(conn))
    @test isnothing(Leaf.password(conn))
    @test isnothing(Leaf.authMechanism(conn))
    @test isnothing(Leaf.authSource(conn))
    
    # --- uri parsing
    metadata = Leaf.parse_uri("mongodb://mongo:27017")
    @test isnothing(metadata["username"]) 
    @test isnothing(metadata["password"])
    @test metadata["host"] == "mongo"
    @test metadata["port"] == 27017
    @test isnothing(metadata["authSource"])
    @test isnothing(metadata["authMechanism"])

    metadata = Leaf.parse_uri("mongodb://user123:mypass@mongo:27017")
    @test metadata["username"] == "user123" 
    @test metadata["password"] == "mypass"
    @test metadata["host"] == "mongo"
    @test metadata["port"] == 27017
    @test isnothing(metadata["authSource"])
    @test isnothing(metadata["authMechanism"])

    metadata = Leaf.parse_uri("mongodb://user123:mypass@mongo:27017/?authSource=source1&authMechanism=mecanism1")
    @test metadata["username"] == "user123" 
    @test metadata["password"] == "mypass"
    @test metadata["host"] == "mongo"
    @test metadata["port"] == 27017
    @test metadata["authSource"] == "source1"
    @test metadata["authMechanism"] == "mecanism1"
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

