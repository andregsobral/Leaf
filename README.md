
## Leaf

### Database CRUD API

**Leaf** defines CRUD methods that serve as an API to interact with different databases. The methods defined are the following:
```julia
# --- CRUD Operations
find_one(), find()
# Returns one or multiple entries of a table/collection from an established database connection. 
# Returns nothing or a vector of objects

delete_one(), delete()
# Deletes one or multiple entries of a table/collection from an established database connection. 
# Returns the deleted count.

update_one(), update()
# Updates one or multiple entries of a table/collection from an established database connection. 
# Returns the updated count.

create()
# Creates one or multiple entries of a table/collection from an established database connection. 
# Returns the inserted count and the ids of each entry.
```

Other auxiliary methods also serve to increase the flexibility of database interactivity:

```julia
# Auxiliar Operations

aggregate()
# An aggregation consists of one or more stages that process entries.«
# - Each stage performs an operation on the input entries. 
# For example, a stage can filter entries, group based on a condition, and calculate values.
# - The entries that are output from a stage are passed to the next stage.
# - An aggregation can return results for groups of entries such as, return the total, average, maximum, and minimum values.  

count()
# Count the number of entries of a collection or table.

drop()
# Destroy a collection or table, i.e, all data associated with that collection is deleted.  

raw()
# Allows the execution of queries that do not fall under the CRUD designation.

```
----

The following examples will be based on a MongoDB connection, since this is the only connection that is currently supported.

### How to define a database connection

Use method `connect` to obtain a `Connection`

```julia
dbname = "leaf_testing"

# --- ex1:
# Simple URI
mongo = Leaf.connect(:mongo, dbname, "mongodb://mongo:27017")

# --- ex2
# URI with authentication
mongo = Leaf.connect(:mongo, dbname, "mongodb://user123:mypass@mongo:27017/?authSource=...&authMechanism=....")

# --- ex3:
# URI via kwargs: host and port
mongo = Leaf.connect(:mongo, dbname, host="mongo", port=27017)

# --- ex4:
# URI via kwargs (all options)
mongo = Leaf.connect(:mongo, dbname, 
    host="mongo", port=27017, username="user123", password="xpto", 
    authSource = "...", authMecanism = "..."
)

```

### How serialization and deserialization works

Serialization and deserialization are based on Julia's native `Base.convert` .

```julia
serialize(db::Database, business_data)   = Base.convert(data_format(db), business_data)
deserialize(datatype::DataType, db_data) = Base.convert(datatype, db_data)
```
If you are querying data, Leaf expects you to have defined a `Base.convert` from the database entry format to the Julia Type. `(ex: Mongoc.BSON -> Company)`

If you are creating or updating data, Leaf expects you to have defined `Base.convert` from the Julia Type to the database entry format. `(ex: Company -> Mongoc.BSON)`

```julia
using Leaf

# ---- Example of how to setup conversion for a MongoDB database
struct Thing
    cust_id ::String
    amount ::Int
    status ::String
end
# ---- Define converters
function Base.convert(::Type{Mongoc.BSON}, thing::Thing)
    return Mongoc.BSON(
        "cust_id" => thing.cust_id, 
        "amount"  => thing.amount, 
        "status"  => thing.status
    )
end
function Base.convert(::Type{Thing}, bson::Mongoc.BSON)
    return Thing(bson["cust_id"], bson["amount"], bson["status"])
end
```

### Associate a type to a collection

Overload method `Leaf.collection`
```julia
Leaf.collection(::Type{Thing}) = "things"
```

### How to query data

After establishing a connection and defining types and collections we can now query data by using the CRUD API

```julia
# Create a Connection
mongo = Leaf.connect(:mongo, "leaf_testing", host="mongo", port=27017)
# --------------------------------------------------------------
# ---- Define type Thing + Base.convert, as seen above.... -----
# --------------------------------------------------------------

# associate collection
Leaf.collection(Type{Thing}) = "things"

# --- all Thing entries in db
mongo.find(Thing)

# --- filter by status
mongo.find(Thing, status = "A")
mongo.find(Thing, """ { "status": "A" } """)

# --- filter by amount
mongo.find(Thing, amount = Dict("\$gt" => 500))
mongo.find(Thing, """ { "amount": {"\$gt": 500} }""")

# --- only first entry
mongo.find_one(Thing, status = "A")
mongo.find_one(Thing, """ { "status": "A" } """)

# --- create an entry
t = Thing("Fender Stratocaster", 799, "Mint")
mongo.create(t)

# --- create multiple
t1 = Thing("Fender Telecaster", 799, "Mint")
t2 = Thing("Fender JazzMaster", 699, "Mint")
t3 = Thing("Fender Jaguar", 599, "SecondHand")

mongo.create([t1,t2,t3])

# --- update one
# use only update info + some id
mongo.update_one(Thing, Dict("amount"=> 900), cust_id = "Fender Stratocaster"))

# use object
t.amount = 1000
mongo.update_one(t, cust_id = "Fender Stratocaster"))  

# --- update many
mongo.update(Thing, Dict("status" => "Sold"), status = "Mint")

# --- delete one
mongo.delete_one(Thing, cust_id = "Fender Stratocaster")

# --- delete many
mongo.delete(Thing, status = "Mint")
```

### Associate Schema and a DataPolicy to a type

A Schema and a DataPolicy can be optionally setup in order for the data to be automatically validated prior to the execution of the ```create``` and ```update``` operations. 

If the data validation is successful, the operation occurs as expected, either creating or updating a record on the database. If the validation is unsuccessful, the ```ValiadationException``` is thrown, the flow of execution is interrupted and thus no record is created or updated in the database.

A Schema is any struct that is a subtype of ```Leaf.Schema```:

```julia
# schema definition
struct ThingSchema <: Leaf.Schema
    cust_id ::String
    amount  ::Int
    status  ::String
end

# conversion from a domain object to the corresponding schema
function Leaf.schema(t::Thing) 
    return ThingSchema(t.cust_id, t.amount, t.status)
end

# which schema is associated to the domain object
function Leaf.scheam_type(::Type{Thing}) 
    return ThingSchema
end
```

The two extra functions ```schema``` and ```schema_type``` must be defined for configuration pourpuses. They tell Leaf how to transform your domain object to the corresponding schema and which schema is associated to the domain object, respectfully. 

By doing only this setup, the following validations are garateed:
1. On ```create``` operations, the document created on the database follows exactly the field and type definitions of the ```Schema```.
2. On ```update``` operations, the changes to field values must match the schema field type (cannot update the ```amount``` with a ```String``` value, only an ```Int``` value)

If more complex validations are necessary, then a DataPolicy for the Schema must be defined by calling the function ```Leaf.DataPolicy!```:

```julia
Leaf.DataPolicy!(ThingSchema, [
    :amount => (fval, args) -> fval > 100,
    :status => (fval, args) -> status in args[:possible_states]
])

```

This policy defines that the field ```amount``` of every ```ThingSchema``` must be over 100 and that the ```status``` must be in the options ```possible_states```. From this point on, any create or update operations will check the modifications against the policy and throw an exception for any invalid data detected.

To set the static data in the policy to be used in the ```args``` field in the policy verifications set the function:


```julia
Leaf.schema_metadata(::Type{ThingSchema}) = Dict(
    :possible_states => ["ready", "set", "go"]
)
```

#### Additional Test and examples

Additional examples available under `/test/mongo/tests.jl`

#### Going forward

My goal is to eventually adapt this approach to various database types instead of only MongoDB.
