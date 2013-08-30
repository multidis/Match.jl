### Utilities used by @match macro
# author: Kevin Squire (@kmsquire)


#
# subslicedim
#
# "sub" version of slicedim, to get an array slice as a view

subslicedim{T<:AbstractArray}(A::T, d::Integer, i) = 
    (if d < 1 || d > ndims(A);  throw(BoundsError()) end; sz = size(A); sub(A, [ n==d ? i : (1:sz[n]) for n in 1:ndims(A) ]...))

subslicedim{T<:AbstractVector}(A::T, d::Integer, i) = 
    (if d != 1;  throw(BoundsError()) end;  A[i])

#
# getsyms
#
# get all symbols in an expression (including undefined symbols)

getsyms(e) = Set{Symbol}()
getsyms(e::Symbol) = Set{Symbol}(e)

function getsyms(e::Expr)
    syms = Set{Symbol}(e.head)
    for a in e.args
        union!(syms, getsyms(a))
    end
    syms
end


#
# varsym
#
# get the symbol from a :(::) expression

varsym(x::Expr) = isexpr(x, :(::)) ? x.args[1] : x
varsym(x::Symbol) = x


#
# check_dim_size_expr
#
# generate an expression to check the size of a variable dimension against an array of expressions

function check_dim_size_expr(val, dim::Integer, ex::Expr)
    if length(ex.args) == 0 || !isexpr(ex.args[end], :(...))
        :($dim <= ndims($val) && size($val, $dim) == $(length(ex.args)))
    else
        :($dim <= ndims($val) && size($val, $dim) >= $(length(ex.args)-1))
    end
end


#
# check_tuple_len_expr
#
# generate an expression to check the length of a tuple variable against a tuple expression

function check_tuple_len_expr(val, ex::Expr)
    if length(ex.args) == 0 || !isexpr(ex.args[end], :(...))
        :(length($val) == $(length(ex.args)))
    else
        :(length($val) >= $(length(ex.args)-1))
    end
end


#
# joinexprs
#
# join an array of (e.g., true/false) expressions with an operator

function joinexprs(exprs::AbstractArray, oper::Symbol, default=:nothing)
    len = length(exprs)

    len == 0 ? default :
    len == 1 ? exprs[1] :
               Expr(oper, exprs...)
end


#
# let_expr
#
# generate an optional let expression

let_expr(expr, assignments::AbstractArray) = 
    length(assignments) > 0 ? Expr(:let, expr, assignments...) : expr

#
# to_array_type
#
# modify x::Type => x::AbstractArray{Type}

function to_array_type(ex::Expr)
    if isexpr(ex, :(::))
        :($(ex.args[1])::AbstractArray{$(ex.args[2])})
    else
        ex
    end
end

to_array_type(sym::Symbol) = :($sym::AbstractArray)

