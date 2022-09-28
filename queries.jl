using InteractiveUtils: subtypes

abstract type Operator{T} end
function (f::Operator{T})(::T)::Bool where T end
function label(::Operator)::String end
opType(::Operator{T}) where T = T

struct Eq <: Operator{Any} end
label(::Eq) = "="
(op::Eq)(test::Any, value::Any)::Bool = test == value
(op::Eq)(test::Bool, value::Any)::Bool = value == (test ? "true" : "false")

struct Ne <: Operator{Any} end
label(::Ne) = "≠"
(op::Ne)(test::Any, value::Any)::Bool = test ≠ value
(op::Ne)(test::Any, value::Bool)::Bool = value ≠ (test ? "true" : "false")

struct Lt <: Operator{Number} end
label(::Lt) = "<"
(op::Lt)(test::Number, value::Number)::Bool = test < value

struct Le <: Operator{Number} end
label(::Le) = "≤"
(op::Le)(test::Number, value::Number)::Bool = test ≤ value

struct Gt <: Operator{Number} end
label(::Gt) = ">"
(op::Gt)(test::Number, value::Number)::Bool = test > value

struct Ge <: Operator{Number} end
label(::Ge) = "≥"
(op::Ge)(test::Number, value::Number)::Bool = test ≥ value

mutable struct PredicateTemplate{T}
  key::String
  operators::Dict{String, Operator}
  values::Set{T}
end
PredicateTemplate(key::String, ::String)  = PredicateTemplate{String}(key, operatorsFor(String), Set{String}())
PredicateTemplate(key::String, ::Nothing) = PredicateTemplate{String}(key, operatorsFor(String), Set{String}())
PredicateTemplate(key::String, ::Number)  = PredicateTemplate{Number}(key, operatorsFor(Number), Set{Number}())
PredicateTemplate(key::String, ::Bool)    = PredicateTemplate{String}(key, operatorsFor(String), Set{String}())
function operatorsFor(T::Type)::Dict{String, Operator} 
  ops = filter((o) -> T <: opType(o), [o() for o in subtypes(Operator)])
  keys = [label(o) for o in ops]
  Dict(keys .=> ops)
end
addValue!(p::PredicateTemplate{String}, v::Bool) = push!(p.values, v ? "true" : "false")
addValue!(p::PredicateTemplate{T}, v::T) where T = push!(p.values, v)
addValue!(p::PredicateTemplate{String}, ::Nothing) = push!(p.values, "")

struct Predicate{T}
  key::String
  op::Operator{T}
  value::T
end
function Predicate(key::String, op::String, val::String, template::PredicateTemplate{String})
  op = template.operators[op]
  Predicate(key, op, val)
end
function Predicate(key::String, op::String, ::Nothing, template::PredicateTemplate{String})
  op = template.operators[op]
  Predicate(key, op, "")
end
function Predicate(key::String, op::String, val::Bool, template::PredicateTemplate{String})
  op = template.operators[op]
  Predicate(key, op, val ? "true" : "false")
end
function Predicate(key::String, op::String, val::String, template::PredicateTemplate{T}) where T <: Number
  op = template.operators[op]
  val = parse(Float64, val)
  val = isinteger(val) ? Int(val) : val
  Predicate(key, op, val)
end


function subset(entries::Vector{Dict{String, Any}}, predicates::Vector{Predicate})::Vector{Dict{String, Any}}
  return filter((e) -> entriesFilter(e, predicates), entries)
end

function entriesFilter(e::Dict{String, Any}, predicates::Vector{Predicate})::Bool
  if length(predicates) == 0
    return true
  end

  for p in predicates
    pe = false
    for (k, v) in e
      pe |= entryFilter(k, v, p)
    end
    if !pe
      return false
    end
  end

  return true
end

function entryFilter(key::String, value::Any, p::Predicate)::Bool
  if key == p.key
    return p.op(value, p.value)
  else
    return false
  end
end

function makeTemplates(entries::Vector{Dict{String, Any}})::Dict{String, PredicateTemplate}
  td = Dict{String, PredicateTemplate}()
  for e in entries
    for (k, v) in e
      if k == "filename"
        continue
      end
      if !haskey(td, k)
        td[k] = PredicateTemplate(k, v)
      end
      addValue!(td[k], v)
    end
  end

  return td
end
