using Dash, DashBootstrapComponents
using JSON, Base64

include("queries.jl")
include("state.jl")
include("ui.jl")

dataDir = ARGS[1]

# url_base_pathname = dash_env("url_base_pathname"),
# requests_pathname_prefix = dash_env("requests_pathname_prefix"),
# routes_pathname_prefix = dash_env("routes_pathname_prefix"),
# 
app = dash(url_base_pathname="/plots/", external_stylesheets=[dbc_themes.SANDSTONE])
app.title = "Plot Browser"

createUi!(app, dataDir)
  
run_server(app, "0.0.0.0", 8080, debug=true)

