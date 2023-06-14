using Glob

mutable struct DiskState
  metadata::Vector{Dict{String, Any}}
  queryTemplates::Dict{String, PredicateTemplate}
end

function loadState(url::String, dataDir::String)::DiskState
  jpath = joinpath(dataDir, "images.json")
  if isfile(jpath)
    j = JSON.parsefile(jpath)
    entries::Vector{Dict{String, Any}} = j["images"]
  else
    ifns = glob("*.json", dataDir)
    entries = [JSON.parsefile(f) for f in ifns]
  end
  for e in entries
    fn = e["filename"]
    e["filename"] = joinpath(dataDir, fn)
  end

  predicateTemplates = makeTemplates(url, entries)

  return DiskState(entries, predicateTemplates)
end
