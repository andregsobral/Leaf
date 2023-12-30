struct ConnectionException <: Exception
    msg::String
end

struct ValidateException <: Exception
    msg::String
end
Base.showerror(io::IO, e::ConnectionException) = print(io, e.msg)
Base.showerror(io::IO, e::ValidateException) = print(io, e.msg, "!")