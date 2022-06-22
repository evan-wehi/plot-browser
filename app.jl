using Dash, DashBootstrapComponents

using JSON, Base64
include("queries.jl")
include("state.jl")
include("ui.jl")

DATA_DIR = "sample"

app = dash(external_stylesheets=[dbc_themes.SANDSTONE])
app.title = "Plot Browser"

state = loadState(DATA_DIR)

createUi!(app, state)
  
run_server(app, "0.0.0.0", debug=true)

