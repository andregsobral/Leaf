using Leaf
using Test
using Dates

struct Company
    _id           :: String                           # "PT01"
    name          :: String                           # "Petro, S.A."
    country       :: String                           # "PT"
    currency      :: String                           # "EUR"
    capital       :: Int
    unit          :: Union{Nothing,String}            # "U", "K", "M"
    repgroup      :: String                           # "COMP_PT"
end

struct DataInstance
    company    :: String                              # "PT01"
    period     :: String                              # "2020-12"
    version    :: Int                                 # 1
    active     :: Bool                                # true (if this is the active data for the company/period)
    currency   :: String                              # "EUR"
    created_by :: String                              # "user001"
    created_at :: DateTime                            # 2021-01-01T15:32:01    
end

struct House
    address       :: String                           # "HardRock Cafe"
    city          :: String                           # "Paris"
    country       :: String                           # "France"
end

struct Attribute
    name  ::String
    attrs ::Dict{String, String}
end

function Base.:(==)(c1::Company, c2::Company) ::Bool
    return c1._id       == c2._id       &&
           c1.name      == c2.name      &&
           c1.country   == c2.country   &&
           c1.currency  == c2.currency  &&
           c1.capital   == c2.capital   &&
           c1.unit      == c2.unit      &&
           c1.repgroup  == c2.repgroup
end

function Base.:(==)(d1::DataInstance, d2::DataInstance) ::Bool
    return d1.company    == d2.company    &&
           d1.period     == d2.period     &&
           d1.version    == d2.version    &&
           d1.currency   == d2.currency   &&
           d1.created_by == d2.created_by &&
           d1.created_at == d2.created_at
end

function Base.:(==)(c1::House, c2::House) ::Bool
    return c1.address == c2.address       &&
           c1.city    == c2.city          &&
           c1.country == c2.country   
end

function Base.:(==)(c1::Attribute, c2::Attribute) ::Bool
    return c1._id   == c2._id  &&
           c1.attrs == c2.attrs    
end

include("mongo/tests.jl")

