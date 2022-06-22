
mutable struct State
  images::Vector{String}
  currentImage::Int
  queries::Dict{String, Predicate}
  queryTemplates::Vector{PredicateTemplate}
  listeners::Vector{Function}
end

State(images::Vector{String}, templates::Vector{PredicateTemplate}) = State(images, 1, Dict{String, Predicate}(), templates, Function[])

function next(s::State)
  if s.currentImage < length(s.images)
    s.currentImage += 1
  end
end
hasNext(s::State) = s.currentImage < length(s.images)

function prev(s::State)
  if s.currentImage > 1
    s.currentImage -= 1
  end
end
hasPrev(s::State) = s.currentImage > 1

function getCurrentImage(s::State)
  fn = joinpath(DATA_DIR, s.images[s.currentImage])
  s = read(fn)
  return "data:image/png;base64," * base64encode(s)
end

function loadState(dataDir::String)::State
  s = read(joinpath(dataDir, "images.json"), String)
  j = JSON.parse(s)
  entries::Vector{Dict{String, Any}} = j["images"]
  images = map(entries) do e
    fn = e["filename"]
    delete!(e, "filename")
    fn
  end

  predicateTemplates = makeTemplates(entries)

  return State(images, predicateTemplates)
end

addListener(state::State, listener::Function) = push!(state.listeners, listener)
notifyListeners(state::State) = map((l) -> l(s), state.listeners)

function addPredicate(state::State, predicate::Predicate) 
  state.predicates[predicate.key] = predicate
  notifyListeners(state)
end
