using Dash, DashBootstrapComponents

navButton(txt, id, disabled) = dbc_button(txt,
color = "primary", 
className = "me-1", 
n_clicks = 0, 
id = id, 
disabled = disabled,
style = Dict("margin" => "10px")
)

navButtons = dbc_buttongroup([
  navButton("< Prev", "prev-button", true),
  navButton("Next >", "next-button", false)
])

function queryForm(app::Dash.DashApp, state::State, predicateTemplate::PredicateTemplate)
  key = predicateTemplate.key
  id = "$(key)-predicate"

  mi = map(predicateTemplate.operators) do op
    Dict("label" => label(op), "value" => label(op))
  end
  push!(mi, Dict("label" => "", "value" => ""))

  f = dbc_inputgroup([
    dbc_inputgrouptext(key, id = "$(key)-label", style = Dict("margin" => "10px"))
    dbc_select(id = "$(key)-op", options = mi, style = Dict("margin" => "10px"))
    dbc_input(id = "$(key)-value", style = Dict("margin" => "10px"))
  ],
  id = id)
  
  callback!(
    app,
    Output("$(key)-label", "value"),
    Input("$(key)-op", "value"),
    Input("$(key)-value", "value"),
    prevent_initial_call = true
    ) do _, _

    println(callback_context().triggered[1].prop_id)

    return no_update()
  end

    html_div(f)
end

function handleImageNavigation(direction::String, state::State)
  if direction == "next-button.n_clicks"
    next(state)
    return getCurrentImage(state), !hasNext(state), !hasPrev(state)
  else
    prev(state)
    return getCurrentImage(state), !hasNext(state), !hasPrev(state)
  end
end

function createUi!(app::Dash.DashApp, state::State)

  queryForms = [queryForm(app, state, tmpl) for tmpl in state.queryTemplates]

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
  prevent_initial_call = true
  ) do _, _
    handleImageNavigation(callback_context().triggered[1].prop_id, state)
  end

end