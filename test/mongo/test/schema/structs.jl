struct HouseSchema <: Leaf.Schema
    address       :: String                           # "HardRock Cafe"
    city          :: String                           # "Paris"
    country       :: String                           # "France"
end
Leaf.schema(x::House)           = HouseSchema(x.address, x.city, x.country)
Leaf.schema_type(::Type{House}) = HouseSchema

# --- data
h1 = House("Rua Manuel Ferreira de Andrade", "Lisboa", "PT")
h2 = House("tiny", "Lisboa", "PT")
h1_schema = Leaf.schema(h1)
h2_schema = Leaf.schema(h2)

