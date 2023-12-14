
function test_return_type(::Type{T}, arr::Array) where T
    return [ @test typeof(val) <: T  for val in arr ]
end

function test_each_item_length(arr::Array, assert_length::Int)
    return [ @test length(val) == assert_length for val in arr ]
end

function test_identical_data(arr::Array, crud_func::Function; test_data_item = first(arr)) 
    for test_items in arr
        if Symbol(crud_func) == :find
            [ @test test_items[i] == test_data_item[i] for i in eachindex(test_items) ]
        elseif Symbol(crud_func) == :find_one
            @test test_items == test_data_item
        end
    end
end

function collect_interfaces_data(::Type{T}, crud_func::Function, query_kwargs::Array, query_dict::Dict, query_string::String) where T
    res = []
    push!(res, getproperty(mongo, Symbol(crud_func))(T; query_kwargs...))
    push!(res, getproperty(mongo, Symbol(crud_func))(T, query_dict))
    push!(res, getproperty(mongo, Symbol(crud_func))(T, query_string))
    push!(res, crud_func(T; query_kwargs...))
    push!(res, crud_func(T, query_dict))
    push!(res, crud_func(T, query_string))
    return res
end

function collect_interfaces_data(::Type{T}, crud_func::Function) where T
    res = []
    push!(res, getproperty(mongo, Symbol(crud_func))(T))
    push!(res, crud_func(T))
    return res
end