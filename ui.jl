using Dash, DashBootstrapComponents

include("content.jl")

STYLE = Dict("margin" => "10px")

navButton(txt, id, disabled) = dbc_button(txt,
  color = "primary", 
  className = "me-1", 
  n_clicks = 0, 
  id = id, 
  disabled = disabled,
  style = STYLE
  )

function queryForm(url::String, state::DiskState, predicateTemplate::PredicateTemplate)
  key = predicateTemplate.key
  id = "$(url)-$(key)-predicate"

  opList = [Dict("label" => label(op), "value" => label(op)) for op in values(predicateTemplate.operators)]
  valList = [Dict("label" => v, "value" => v) for v in predicateTemplate.values]
  
  store = dcc_store(id = "$(key)-store")

  ll = join(split(key, "-")[2:end], "-")

  form = dbc_inputgroup([
    dbc_inputgrouptext(ll, id = "$(url)-$(key)-label", style = STYLE)
    dbc_select(id = "$(key)-op", options = opList, style = STYLE)
    dbc_select(id = "$(key)-value", options = valList, style = STYLE)
    dbc_button("X", id = "$(key)-clear", color = "light", style = STYLE)
    store
  ],
  id = id)
  
  
  html_div(form, style = Dict("maxWidth" => "800px"))
end

function addQueryFormCallbacks!(app::Dash.DashApp, predicateTemplate::PredicateTemplate)
  key = predicateTemplate.key
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

function handleFormAndNavigation(ctx::Dash.CallbackContext, diskState::DiskState, url::String)
  inputElement = ctx.triggered[1].prop_id

  state = ctx.states["$(url)-global-state.data"]
  state = Dict("currentIndex" => state["currentIndex"], "images" => state["images"])
  
  if contains(inputElement, "button")
    return handleNavigation(inputElement, state, url)
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

  return getCurrentImageContent(state), !hasNext(state), !hasPrev(state), state
end

function handleNavigation(direction::String, state::Dict{String, Any}, url::String)
  if direction == "$(url)-next-button.n_clicks"
    next(state)
    return getCurrentImageContent(state), !hasNext(state), !hasPrev(state), state
  else
    prev(state)
    return getCurrentImageContent(state), !hasNext(state), !hasPrev(state), state
  end
end

function createUi(url::String, dataDir::String)
  diskState = loadState(url, dataDir)
  state = viewState(diskState)

  navButtons = dbc_buttongroup([
    navButton("< Prev", "$(url)-prev-button", true),
    navButton("Next >", "$(url)-next-button", false)
  ])

  tmpls = values(diskState.queryTemplates)
  queryForms = [queryForm(url, diskState, tmpl) for tmpl in tmpls]

  layout = dbc_container([
    html_center([
      html_div([
        dbc_row([
          dbc_col(wrapCurrentImage(state, url))
          dbc_col(html_div([
            navButtons
            queryForms...
          ]))
        ])
      ])
    ])
    dcc_store(id = "$(url)-global-state", data=state)
  ])

  return layout
end

function addCallbacks!(app::Dash.DashApp, url::String, dataDir::String)
  diskState = loadState(url, dataDir)
  tmpls = values(diskState.queryTemplates)
  stores = [Input("$(tmpl.key)-store", "data") for tmpl in tmpls]

  callback!(
    app,
    Output("$(url)-image", "src"),
    Output("$(url)-next-button", "disabled"),
    Output("$(url)-prev-button", "disabled"),
    Output("$(url)-global-state", "data"),
    Input("$(url)-next-button", "n_clicks"),
    Input("$(url)-prev-button", "n_clicks"),
    stores...,
    State("$(url)-global-state", "data"),
    prevent_initial_call = true
    ) do _...
      handleFormAndNavigation(callback_context(), diskState, url)
    end

    for tmpl in tmpls
      addQueryFormCallbacks!(app, tmpl)
    end
end

containerForContent(c::Content, ::String) = error("No container for $(c)")
containerForContent(c::ImageContent, id::String) = html_img(src=getContentData(c), id=id)

containerForContent(c::HTMLContent, id::String) = html_embed(src=getContentData(c), id=id, type="text/html", height=600, width=800)

function wrapCurrentImage(state, url)
  i = getCurrentImage(state)
  return containerForContent(i, "$(url)-image")
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

function getCurrentImageContent(s::Dict{String, Any})::String
  i = getCurrentImage(s)
  return getContentData(i)
end
  
function getCurrentImage(s::Dict{String, Any})::Content
  if length(s["images"]) == 0
    i = NoContent("bad metadata")
  end

  fn = s["images"][s["currentIndex"]]

  if isfile(fn)
    i = contentFromFile(fn)
  else
    i = MissingContent()
  end

  return i
end