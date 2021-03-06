using Match
using Base.Test
using Compat

#require("testtypes.jl")
include("testtypes.jl")

import Base: show

# Type matching
test1(item) = @match item begin
    n::Int               => "Integers are awesome!"
    str::AbstractString  => "Strings are the best"
    m::Dict{Int, AbstractString} => "Ints for Strings?"
    d::Dict              => "A Dict! Looking up a word?"
    _                    => "Something unexpected"
end

d = @compat Dict{Int,AbstractString}(1=>"a",2=>"b")

@test test1(66)     == "Integers are awesome!"
@test test1("abc")  == "Strings are the best"
@test test1(d)      == "Ints for Strings?"
@test test1(Dict()) == "A Dict! Looking up a word?"
@test test1(2.0)    == "Something unexpected"


# Pattern extraction
# inspired by http://thecodegeneral.wordpress.com/2012/03/25/switch-statements-on-steroids-scala-pattern-matching/

# type Address
#     street::AbstractString
#     city::AbstractString
#     zip::AbstractString
# end

# type Person
#     firstname::AbstractString
#     lastname::AbstractString
#     address::Address
# end

test2(person) = @match person begin
    Person("Julia", lastname,  _) => "Found Julia $lastname"
    Person(firstname, "Julia", _) => "$firstname Julia was here!"
    Person(firstname, lastname ,Address(_, "Cambridge", zip)) => "$firstname $lastname lives in zip $zip"
    _::Person  => "Unknown person!"
end

@test test2(Person("Julia", "Robinson", Address("450 Serra Mall", "Stanford", "94305")))         == "Found Julia Robinson"
@test test2(Person("Gaston", "Julia",   Address("1 rue Victor Cousin", "Paris", "75005")))       == "Gaston Julia was here!"
@test test2(Person("Edwin", "Aldrin",   Address("350 Memorial Dr", "Cambridge", "02139")))       == "Edwin Aldrin lives in zip 02139"
@test test2(Person("Linus", "Pauling",  Address("1200 E California Blvd", "Pasadena", "91125"))) == "Unknown person!"  # Really?


# Guards, pattern extraction
# translated from Scala Case-classes http://docs.scala-lang.org/tutorials/tour/case-classes.html

##
## Untyped lambda calculus definitions
##

# abstract Term

# immutable Var <: Term
#     name::AbstractString
# end

# immutable Fun <: Term
#     arg::AbstractString
#     body::Term
# end

# immutable App <: Term
#     f::Term
#     v::Term
# end

# scala defines these automatically...
==(x::Var, y::Var) = x.name == y.name
==(x::Fun, y::Fun) = x.arg == y.arg && x.body == y.body
==(x::App, y::App) = x.f == y.f && x.v == y.v


# Not really the Julian way
function show(io::IO, term::Term)
    @match term begin
       Var(n)    => print(io, n)
       Fun(x, b) => begin
                        print(io, "^$x.")
                        show(io, b)
                    end
       App(f, v) => begin
                        print(io, "(")
                        show(io, f)
                        print(io, " ")
                        show(io, v)
                        print(io, ")")
                    end
    end
end

# Guard test is here
function is_identity_fun(term::Term)
   @match term begin
     Fun(x, Var(y)), if x == y end => true
     _ => false
   end
end


id = Fun("x", Var("x"))
t = Fun("x", Fun("y", App(Var("x"), Var("y"))))

let io = IOBuffer()
    show(io, id)
    @assert takebuf_string(io) == "^x.x"
    show(io, t)
    @assert takebuf_string(io) == "^x.^y.(x y)"
    @assert is_identity_fun(id)
    @assert !is_identity_fun(t)
end

# Test single terms

myisodd(x::Int) = @match(x, i => i%2==1)
@assert filter(myisodd, 1:10) == filter(isodd, 1:10) == [1,3,5,7,9]

# Alternatives, Guards

function parse_arg(arg::AbstractString, value::Any=nothing)
   @match (arg, value) begin
      ("-l",              lang),   if lang != nothing end => "Language set to $lang"
      ("-o" || "--optim", n::Int),      if 0 < n <= 5 end => "Optimization level set to $n"
      ("-o" || "--optim", n::Int)                         => "Illegal optimization level $(n)!"
      ("-h" || "--help",  nothing)                        => "Help!"
      bad                                                 => "Unknown argument: $bad"
   end
end

@assert parse_arg("-l", "eng")  == "Language set to eng"
@assert parse_arg("-l")         == "Unknown argument: (\"-l\",nothing)"
@assert parse_arg("-o", 4)      == "Optimization level set to 4"
@assert parse_arg("--optim", 5) == "Optimization level set to 5"
@assert parse_arg("-o", 0)      == "Illegal optimization level 0!"
@assert parse_arg("-o", 1.0)    == "Unknown argument: (\"-o\",1.0)"

@assert parse_arg("-h") == parse_arg("--help") == "Help!"


# Regular Expressions

# TODO: Fix me!

# Note: the following test only works because Ipv4Addr and EmailAddr
# are (module-level) globals!

# const Ipv4Addr = r"(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})"
# const EmailAddr = r"\b([A-Z0-9._%+-]+)@([A-Z0-9.-]+\.[A-Z]{2,4})\b"i

# function regex_test(str)
#     ## Defining these in the function doesn't work, because the macro
#     ## (and related functions) don't have access to the local
#     ## variables.

#     # Ipv4Addr = r"(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})"
#     # EmailAddr = r"\b([A-Z0-9._%+-]+)@([A-Z0-9.-]+\.[A-Z]{2,4})\b"i

#     @match str begin
#         Ipv4Addr(_, _, octet3, _),       if int(octet3) > 30 end => "IPv4 address with octet 3 > 30"
#         Ipv4Addr()                                               => "IPv4 address"

#         EmailAddr(_,domain), if endswith(domain, "ucla.edu") end => "UCLA email address"
#         EmailAddr                                                => "Some email address"

#         r"MCM.*"                                                 => "In the twentieth century..."

#         _                                                        => "No match"
#     end
# end

# @assert regex_test("128.97.27.37")                 == "IPv4 address"
# @assert regex_test("96.17.70.24")                  == "IPv4 address with octet 3 > 30"

# @assert regex_test("beej@cs.ucla.edu")             == "UCLA email address"
# @assert regex_test("beej@uchicago.edu")            == "Some email address"

# @assert regex_test("MCMLXXII")                     == "In the twentieth century..."
# @assert regex_test("Open the pod bay doors, HAL.") == "No match"


# Pattern extraction from arrays

# extract first, rest from array
# (b is a subarray of the original array)
@assert @match([1:4;], [a,b...])                             == (1,[2,3,4])
@assert @match([1:4;], [a...,b])                             == ([1,2,3],4)
@assert @match([1:4;], [a,b...,c])                           == (1,[2,3],4)

# match particular values at the beginning of a vector
@assert @match([1:10;], [1,2,a...])                          == [3:10;]
@assert @match([1:10;], [1,a...,9,10])                       == [2:8;]

# match / collect columns
@assert @match([1 2 3; 4 5 6], [a b...])                    == ([1,4] , [2 3; 5 6])
@assert @match([1 2 3; 4 5 6], [a... b])                    == ([1 2; 4 5] , [3,6])
@assert @match([1 2 3; 4 5 6], [a b c])                     == ([1,4] , [2,5] , [3,6])
@assert @match([1 2 3; 4 5 6], [[1,4] a b])                 == ([2,5] , [3,6])

@assert @match([1 2 3 4; 5 6 7 8], [a b... c])              == ([1,5] , [2 3; 6 7] , [4,8])

# match / collect rows
@assert @match([1 2 3; 4 5 6], [a, b])                      == ([1 2 3], [4 5 6])
@assert @match([1 2 3; 4 5 6], [[1 2 3], a])                ==  [4 5 6]             # TODO: don't match this
@assert @match([1 2 3; 4 5 6], [1 2 3; a])                  ==  [4 5 6]

@assert @match([1 2 3; 4 5 6; 7 8 9], [a, b...])            == ([1 2 3], [4 5 6; 7 8 9])
@assert @match([1 2 3; 4 5 6; 7 8 9], [a..., b])            == ([1 2 3; 4 5 6], [7 8 9])
@assert @match([1 2 3; 4 5 6; 7 8 9], [1 2 3; a...])        ==  [4 5 6; 7 8 9]

@assert @match([1 2 3; 4 5 6; 7 8 9; 10 11 12], [a,b...,c]) == ([1 2 3], [4 5 6; 7 8 9], [10 11 12])

# match invidual positions
@assert @match([1 2; 3 4], [1 a; b c])                      == (2,3,4)
@assert @match([1 2; 3 4], [1 a; b...])                     == (2,[3 4])

@assert @match([ 1  2  3  4
                 5  6  7  8
                 9 10 11 12
                13 14 15 16
                17 18 19 20 ],

                [1      a...
                 b...
                 c... 15 16
                 d 18 19 20])                               == ([2 3 4], [5 6 7 8; 9 10 11 12], [13 14], 17)

# match 3D arrays
m = reshape([1:8;], (2,2,2))
@assert @match(m, [a b])                                    == ([1 3; 2 4], [5 7; 6 8])
@assert @match(m, [[1 a; b c] d])                           == (3,2,4,[5 7; 6 8])

# match against an expression
function get_args(ex::Expr)
    @match ex begin
        Expr(:call, [:+, args...], _) => args
        _ => "None"
    end
end

@assert get_args(Expr(:call, :+, :x, 1)) == [:x, 1]

# Zach Allaun's fizzbuzz (https://github.com/zachallaun/Match.jl#awesome-fizzbuzz)

function fizzbuzz(range::Range)
    io = IOBuffer()
    for n in range
        @match (n%3, n%5) begin
            (0,0) => print(io, "fizzbuzz ")
            (0,_) => print(io, "fizz ")
            (_,0) => print(io, "buzz ")
            (_,_) => print(io, n, ' ')
        end
    end
    takebuf_string(io)
end

@assert fizzbuzz(1:15) == "1 2 fizz 4 buzz fizz 7 8 fizz buzz 11 fizz 13 14 fizzbuzz "

# Zach Allaun's "Balancing Red-Black Trees" (https://github.com/zachallaun/Match.jl#balancing-red-black-trees)

abstract RBTree

immutable Leaf <: RBTree
end

immutable Red <: RBTree
    value
    left::RBTree
    right::RBTree
end

immutable Black <: RBTree
    value
    left::RBTree
    right::RBTree
end

function balance(tree::RBTree)
    @match tree begin
        ( Black(z, Red(y, Red(x, a, b), c), d)
         || Black(z, Red(x, a, Red(y, b, c)), d)
         || Black(x, a, Red(z, Red(y, b, c), d))
         || Black(x, a, Red(y, b, Red(z, c, d)))) => Red(y, Black(x, a, b),
                                                         Black(z, c, d))
        tree => tree
    end
end

@assert balance(Black(1, Red(2, Red(3, Leaf(), Leaf()), Leaf()), Leaf())) ==
            Red(2, Black(3, Leaf(), Leaf()),
                Black(1, Leaf(), Leaf()))


function num_match(n)
    @match n begin
        0      => "zero"
        1 || 2 => "one or two"
        3:10   => "three to ten"
        _      => "something else"
    end
end

@assert num_match(0) == "zero"
@assert num_match(2) == "one or two"
@assert num_match(4) == "three to ten"
@assert num_match(12) == "something else"
@assert num_match("hi") == "something else"
@assert num_match('c') == "something else"
