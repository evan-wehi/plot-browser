using InteractiveUtils: subtypes

abstract type Operator{T} end
function (f::Operator{T})(::T)::Bool where T end
function label(::Operator)::String end
opType(::Operator{T}) where T = T

struct Eq <: Operator{Any} end
label(::Eq) = "="
(op::Eq)(test::Any)::Bool = test == op.value

struct Ne <: Operator{Any} end
label(::Ne) = "≠"
(op::Ne)(test::Any)::Bool = test ≠ op.value

struct Lt <: Operator{Number} end
label(::Lt) = "<"
(op::Lt)(test::Number)::Bool = test < op.value

struct Le <: Operator{Number} end
label(::Le) = "≤"
(op::Le)(test::Number)::Bool = test ≤ op.value

struct Gt <: Operator{Number} end
label(::Gt) = ">"
(op::Gt)(test::Number)::Bool = test > op.value

struct Ge <: Operator{Number} end
label(::Ge) = "≥"
(op::Ge)(test::Number)::Bool = test ≥ op.value

struct PredicateTemplate{T}
  key::String
  operators::Vector{Operator}
end
PredicateTemplate(key::String, ::String) = PredicateTemplate{String}(key, operatorsFor(String))
PredicateTemplate(key::String, ::Number) = PredicateTemplate{Number}(key, operatorsFor(Number))
operatorsFor(T::Type)::Vector{Operator} = filter((o) -> T <: opType(o), [o() for o in subtypes(Operator)])

struct Predicate{T}
  key::String
  op::Operator{T}
  value::T
end

function subset(entries::Vector{Dict{String, Any}}, predicates::Vector{Predicate})::Vector{Dict{String, Any}}
  return filter((e) -> entriesFilter(e, predicates), entries)
end

function entriesFilter(e::Dict{String, Any}, predicates::Vector{Predicate})::Bool
  for (k, v) in e
    t = entryFilter(k, v, predicates)
    if !t
      return false
    end
  end

  return true
end

function entryFilter(key::String, value::Any, predicates::Vector{Predicate})::Bool
  for p in predicates
    if key == p.key
      return p.op(value)
    end
  end

  return true
end

function makeTemplates(entries::Vector{Dict{String, Any}})::Vector{PredicateTemplate}
  td = Dict{String, PredicateTemplate}()
  for e in entries
    for (k, v) in e
      td[k] = PredicateTemplate(k, v)
    end
  end

  return collect(values(td))
end
