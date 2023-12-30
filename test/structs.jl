abstract type TestStruct end

struct Company <: TestStruct
    _id           :: String                           # "PT01"
    name          :: String                           # "Petro, S.A."
    country       :: String                           # "PT"
    currency      :: String                           # "EUR"
    capital       :: Int
    unit          :: Union{Nothing,String}            # "U", "K", "M"
    repgroup      :: String                           # "COMP_PT"
end

struct DataInstance <: TestStruct
    company    :: String                              # "PT01"
    period     :: String                              # "2020-12"
    version    :: Int                                 # 1
    active     :: Bool                                # true (if this is the active data for the company/period)
    currency   :: String                              # "EUR"
    created_by :: String                              # "user001"
    created_at :: DateTime                            # 2021-01-01T15:32:01    
end

struct House <: TestStruct
    address       :: String                           # "HardRock Cafe"
    city          :: String                           # "Paris"
    country       :: String                           # "France"
end

struct Attribute <: TestStruct
    name  ::String
    attrs ::Dict{String, String}
end

# ===== Struct testing comparisons

# Compares if each field for a given struct is the same
function basic_struct_comparator(x1::TestStruct, x2::TestStruct)
    @assert typeof(x1) == typeof(x2) "Comparison of different data types!\n\tIt can only compare matching data stypes.\n\t($(typeof(x1)) != $(typeof(x2)))"
    field_comparisons = [ getfield(x1, f) == getfield(x2, f)  for f in fieldnames(typeof(x1)) ]
    return Base.:&(field_comparisons...)
end

function Base.:(==)(c1::TestStruct, c2::TestStruct) ::Bool
    return basic_struct_comparator(c1,c2)
end
