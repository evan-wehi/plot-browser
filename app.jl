using Dash, DashBootstrapComponents
using JSON, Base64, ArgParse

include("queries.jl")
include("state.jl")
include("ui.jl")

function _fix_slashes(u::String)
  if !startswith(u, '/')
    u = '/' * u 
  end
  if !endswith(u, '/')
    u = u *'/'
  end
  return u
end

function _remove_slashes(u::String)
  if startswith(u, '/')
    u = u[2:end]
  end
  if endswith(u, '/')
    u = u[1:end-1]
  end
  return u
end

struct Route
  path::String
  url::String
  Route(p::String, u::String) = new(p, _remove_slashes(u))
end
function makeRouteDict(routes::Vector{Route})::Dict{String, Route}
  d = Dict{String, Route}()
  for r in routes
    d[r.url] = r
  end
  return d
end

function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table! s begin
      "--paths"
      help = "A list of local filesystem paths with images and metadata to served"
      required = true
      arg_type = String
      nargs = '*'

      "--urls"
      help = "A list of base URLs for the directories"
      required = true
      arg_type = String
      nargs = '*'

      "--base-url"
      help = "the base url"
      required = false
      arg_type = String
      default = "/"
  end

  return parse_args(s)
end

function parseAppUrl(url::String)::Union{Nothing, String}
  p = _remove_slashes(url)
  bits = split(p, "/")
  if length(bits) == 0
    return nothing
  else
    return bits[end]
  end
end

function makeApp(; url_base_pathname="/", routes=Route[])
  # Multipage app example:
  # https://gitlab.com/etpinard/dash.jl-multi-page-app-example

  url_base_pathname = _fix_slashes(url_base_pathname)
  routeDict = makeRouteDict(routes)

  app = dash(
  url_base_pathname=url_base_pathname, 
  suppress_callback_exceptions=true,
  prevent_initial_callbacks=true,
  external_stylesheets=[dbc_themes.SANDSTONE])
  app.title = "Plot Browser"
  app.layout = html_div([dcc_location(; id="url"),  # page URL as a component
  html_div(; id="content")]) # page content goes here

  callback!(app, Output("content", "children"),
                 Input("url", "pathname")) do url
    u = parseAppUrl(url)
    if u === nothing
      return 404
    end

    if haskey(routeDict, u)
      route = routeDict[u]
      layout = createUi(route.url, route.path)
      return layout
    else
      return 404
    end
  end

  for r in routes
    addCallbacks!(app, r.url, r.path)
  end

  return app
end

function main()
  parsed_args = parse_commandline()
  paths = parsed_args["paths"]
  urls = parsed_args["urls"]
  base_url = parsed_args["base-url"]

  if length(paths) != length(urls)
    error("There must as many directories as urls")
  end

  routes = [Route(d, u) for (d, u) in zip(paths, urls)]

  app = makeApp(; url_base_pathname=base_url, routes=routes)

  run_server(app, "0.0.0.0", 8080, debug=true)
end

  main()
