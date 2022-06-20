using Dash, DashBootstrapComponents, JSON, Base64
app = dash(external_stylesheets=[dbc_themes.SANDSTONE])

DATA_DIR = "sample"

@enum Op eq ne ge gt le lt
struct Predicate{T}
  key::String
  op::Op
  value::T
end

struct State
  images::Vector{String}
  currentImage::Int
  query::Vector{Predicate}
end
State(images::Vector{String}) = State(images, 1, [])

function getCurrentImage(s::State)
  fn = joinpath(DATA_DIR, s.images[s.currentImage])
  s = read(fn)
  return "data:image/png;base64," * base64encode(s)
end

function loadData()::State
  s = read("sample/images.json", String)
  j = JSON.parse(s)
  images = [i["filename"] for i in j["images"]]
  return State(images)
end


state = loadData()

buttons = dbc_buttongroup([
    dbc_button("< Prev", color = "primary", className = "me-1"),
    dbc_button("Next >", color = "primary", className = "me-1")
])

app.layout = dbc_container([
  html_div(
    html_img(src=getCurrentImage(state))
  )
  buttons
]
)

run_server(app, "0.0.0.0", debug=true)
