
mutable struct DiskState
  metadata::Vector{Dict{String, Any}}
  queryTemplates::Dict{String, PredicateTemplate}
end

function loadState(url::String, dataDir::String)::DiskState
  s = read(joinpath(dataDir, "images.json"), String)
  j = JSON.parse(s)
  entries::Vector{Dict{String, Any}} = j["images"]
  for e in entries
    fn = e["filename"]
    e["filename"] = joinpath(dataDir, fn)
  end

  predicateTemplates = makeTemplates(url, entries)

  return DiskState(entries, predicateTemplates)
end
