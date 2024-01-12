abstract type LeafException <: Exception end

struct ConnectionException <: LeafException
    msg::String
end
struct ValidationException <: LeafException
    msg::String
    field::Symbol
    val
    schema::DataType
end
function ValidationException(field::Symbol, val, T::DataType)
    msg = "Invalid '$(T)' object:\n [$T.$field]: '$val'\n Value does not comply with the schema's data policy for field '$field'"
    return ValidationException(msg, field, val, T)
end
# --- Generic Leaf.Exception show error
Base.showerror(io::IO, e::LeafException) = print(io, e.msg)
