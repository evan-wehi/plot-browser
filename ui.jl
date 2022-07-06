using Dash, DashBootstrapComponents

navButton(txt, id, disabled) = dbc_button(txt,
  color = "primary", 
  className = "me-1", 
  n_clicks = 0, 
  id = id, 
  disabled = disabled,
  style = Dict("margin" => "10px")
  )

function queryForm(app::Dash.DashApp, state::DiskState, predicateTemplate::PredicateTemplate)
  key = predicateTemplate.key
  id = "$(key)-predicate"

  opList = [Dict("label" => label(op), "value" => label(op)) for op in values(predicateTemplate.operators)]
  valList = [Dict("label" => v, "value" => v) for v in predicateTemplate.values]
  
  store = dcc_store(id = "$(key)-store")

  form = dbc_inputgroup([
    dbc_inputgrouptext(key, id = "$(key)-label", style = Dict("margin" => "10px"))
    dbc_select(id = "$(key)-op", options = opList, style = Dict("margin" => "10px"))
    dbc_select(id = "$(key)-value", options = valList, style = Dict("margin" => "10px"))
    dbc_button("X", id = "$(key)-clear", color = "light", style = Dict("margin" => "10px"))
    store
  ],
  id = id)
  
  callback!(
    app,
    Output("$(key)-store", "data"),
    Output("$(key)-op", "value"),
    Output("$(key)-value", "value"),
    Input("$(key)-op", "value"),
    Input("$(key)-value", "value"),
    Input("$(key)-clear", "n_clicks"),
    prevent_initial_call = true
    ) do _, _, _
    return handlePredicateCallback(key, callback_context())
  end
  
  html_div(form, style = Dict("max-width" => "800px"))
end

function handlePredicateCallback(key::String, ctx::Dash.CallbackContext)
  # Context is "documented" here:
  # https://github.com/plotly/Dash.jl/blob/dev/src/handler/callback_context.jl
  # mutable struct CallbackContext
  #   response::HTTP.Response
  #   inputs::Dict{String, Any}
  #   states::Dict{String, Any}
  #   outputs_list::Vector{Any}
  #   inputs_list::Vector{Any}
  #   states_list::Vector{Any}
  #   triggered::Vector{TriggeredParam}
  #   function CallbackContext(response, outputs_list, inputs_list, states_list, changed_props)
  #       input_values = inputs_list_to_dict(inputs_list)
  #       state_values = inputs_list_to_dict(states_list)
  #       triggered = TriggeredParam[(prop_id = id, value = input_values[id]) for id in changed_props]
  #       return new(response, input_values, state_values, outputs_list, inputs_list, states_list, triggered)
  #   end
  # end

  cleared = ctx.triggered[1].prop_id == "$(key)-clear.n_clicks"
  op = ctx.inputs["$(key)-op.value"]
  op = op == "" ? nothing : op
  val = ctx.inputs["$(key)-value.value"]
  val = val == "" ? nothing : val

  if cleared
    return nothing, "", ""
  end

  if val === nothing || op === nothing
    return no_update()
  end

  return Dict(:op => op, :val => val), op, val
end

function handleFormAndNavigation(ctx::Dash.CallbackContext, diskState::DiskState)
  inputElement = ctx.triggered[1].prop_id

  state = ctx.states["global-state.data"]
  state = Dict("currentIndex" => state["currentIndex"], "images" => state["images"])
  
  if contains(inputElement, "button")
    return handleNavigation(inputElement, state)
  end

  filters = Predicate[]
  for input in ctx.inputs_list
    id = input["id"]
    if contains(id, "store")
      if haskey(input, "value")
        v = input["value"]
        if v !== nothing
          key = first(id, length(id)-6)
          op = v["op"]
          val = v["val"]
          p = Predicate(key, op, val, diskState.queryTemplates[key])
          push!(filters, p)
        end
      end
    end
  end
  
  state = viewState(diskState, filters)

  return getCurrentImage(state), !hasNext(state), !hasPrev(state), state
end

function handleNavigation(direction::String, state::Dict{String, Any})
  if direction == "next-button.n_clicks"
    next(state)
    return getCurrentImage(state), !hasNext(state), !hasPrev(state), state
  else
    prev(state)
    return getCurrentImage(state), !hasNext(state), !hasPrev(state), state
  end
end

function createUi!(app::Dash.DashApp, dataDir::String)
  diskState = loadState(dataDir)
  state = viewState(diskState)

  navButtons = dbc_buttongroup([
    navButton("< Prev", "prev-button", true),
    navButton("Next >", "next-button", false)
  ])

  tmpls = values(diskState.queryTemplates)
  queryForms = [queryForm(app, diskState, tmpl) for tmpl in tmpls]
  stores = [Input("$(tmpl.key)-store", "data") for tmpl in tmpls]

  app.layout = dbc_container([
  html_center([
    html_div(
      html_img(src=getCurrentImage(state), id="image")
    )
    navButtons
    queryForms...
  ])
  dcc_store(id = "global-state", data=state)
])

callback!(
  app,
  Output("image", "src"),
  Output("next-button", "disabled"),
  Output("prev-button", "disabled"),
  Output("global-state", "data"),
  Input("next-button", "n_clicks"),
  Input("prev-button", "n_clicks"),
  stores...,
  State("global-state", "data"),
  prevent_initial_call = true
  ) do _...
    handleFormAndNavigation(callback_context(), diskState)
  end

end

viewState(diskState::DiskState) = viewState(diskState, Predicate[])
function viewState(diskState::DiskState, predicates::Vector{Predicate})
  d = Dict{String, Any}()
  d["currentIndex"] = 1
  d["images"] = [md["filename"] for md in subset(diskState.metadata, predicates)]
  d
end
function next(s::Dict{String, Any})
  if s["currentIndex"] < length(s["images"])
    s["currentIndex"] += 1
  end
end
hasNext(s::Dict{String, Any}) = s["currentIndex"] < length(s["images"])

function prev(s::Dict{String, Any})
  if s["currentIndex"] > 1
    s["currentIndex"] -= 1
  end
end
hasPrev(s::Dict{String, Any}) = s["currentIndex"] > 1

function getCurrentImage(s::Dict{String, Any})
  if length(s["images"]) == 0
    return nothing
  end

  fn = s["images"][s["currentIndex"]]
  s = read(fn)
  
  return "data:image/png;base64," * base64encode(s)
end