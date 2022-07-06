using Dash, DashBootstrapComponents

using JSON, Base64
include("queries.jl")
include("state.jl")
include("ui.jl")

dataDir = ARGS[1]

app = dash(external_stylesheets=[dbc_themes.SANDSTONE])
app.title = "Plot Browser"

createUi!(app, dataDir)
  
run_server(app, "0.0.0.0", debug=true)

