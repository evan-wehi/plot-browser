using Dash, DashBootstrapComponents

navButton(txt, id, disabled) = dbc_button(txt,
  color = "primary", 
  className = "me-1", 
  n_clicks = 0, 
  id = id, 
  disabled = disabled,
  style = Dict("margin" => "10px")
  )

function queryForm(app::Dash.DashApp, state::State, predicateTemplate::PredicateTemplate)
  key = predicateTemplate.key
  id = "$(key)-predicate"

  opList = [Dict("label" => label(op), "value" => label(op)) for op in predicateTemplate.operators]
  
  valueList = [Dict("label" => v, "value" => v) for v in predicateTemplate.values]

  store = dcc_store(id = "$(key)-store")

  form = dbc_inputgroup([
    dbc_inputgrouptext(key, id = "$(key)-label", style = Dict("margin" => "10px"))
    dbc_select(id = "$(key)-op", options = opList, style = Dict("margin" => "10px"))
    dbc_select(id = "$(key)-value", options = valueList, style = Dict("margin" => "10px"))
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
  # Contexr is "documented" here:
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
  val = ctx.inputs["$(key)-value.value"]

  if cleared
    return nothing, "", ""
  end

  if val === nothing || op === nothing
    return no_update()
  end

  return Dict(:op => op, :val => val), op, val
end

function handleFormAndNavigation(ctx::Dash.CallbackContext, state::State)
  inputElement = ctx.triggered[1].prop_id
  if contains(inputElement, "button")
    return handleNavigation(inputElement, state)
  end

  # filterDict = Predicate[]
  for input in ctx.inputs_list
    id = input["id"]
    if contains(id, "store")
      if haskey(input, "value")
        v = input["value"]
        if v !== nothing
          key = first(id, length(id)-6)
          op = v["op"]
          val = v["val"]
          println("key=$(key), op=$(op) val=$(val)")
        end
      end
    end
  end

  return no_update()
end

function handleNavigation(direction::String, state::State)
  if direction == "next-button.n_clicks"
    next(state)
    return getCurrentImage(state), !hasNext(state), !hasPrev(state)
  else
    prev(state)
    return getCurrentImage(state), !hasNext(state), !hasPrev(state)
  end
end

function createUi!(app::Dash.DashApp, dataDir::String)
  state = loadState(dataDir)

  navButtons = dbc_buttongroup([
    navButton("< Prev", "prev-button", true),
    navButton("Next >", "next-button", false)
  ])

  queryForms = [queryForm(app, state, tmpl) for tmpl in state.queryTemplates]
  stores = [Input("$(tmpl.key)-store", "data") for tmpl in state.queryTemplates]

  app.layout = dbc_container([
  html_center([
    html_div(
      html_img(src=getCurrentImage(state), id="image")
    )
    navButtons
    queryForms...
  ])
])

callback!(
  app,
  Output("image", "src"),
  Output("next-button", "disabled"),
  Output("prev-button", "disabled"),
  Input("next-button", "n_clicks"),
  Input("prev-button", "n_clicks"),
  stores...,
  prevent_initial_call = true
  ) do _...
    handleFormAndNavigation(callback_context(), state)
  end

end