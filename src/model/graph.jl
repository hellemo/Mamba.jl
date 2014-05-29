#################### MCMCModel Graph Methods ####################

function any_stochastic(v::KeyVertex{Symbol}, g::AbstractGraph, m::MCMCModel)
  found = false
  for v in out_neighbors(v, g)
    if isa(m[v.key], MCMCStochastic) || any_stochastic(v, g, m)
      found = true
      break
    end
  end
  found
end

function gettargets(v::KeyVertex{Symbol}, g::AbstractGraph, m::MCMCModel)
  values = Symbol[]
  for v in out_neighbors(v, g)
    push!(values, v.key)
    if !isa(m[v.key], MCMCStochastic)
      values = union(values, gettargets(v, g, m))
    end
  end
  values
end

function graph(m::MCMCModel)
  g = graph(KeyVertex{Symbol}[], Edge{KeyVertex{Symbol}}[])
  lookup = (Symbol => Integer)[]
  for key in keys(m, :all)
    lookup[key] = length(lookup) + 1
    add_vertex!(g, KeyVertex(lookup[key], key))
  end
  V = vertices(g)
  for dep in keys(m, :dependent)
    for src in m[dep].sources
      add_edge!(g, V[lookup[src]], V[lookup[dep]])
    end
  end
  g
end

function graph2dot(m::MCMCModel)
  g = graph(m)
  str = "digraph MCMCModel {\n"
  deps = keys(m, :dependent)
  for v in vertices(g)
    attr = (String => String)[]
    if in(v.key, deps)
      node = m[v.key]
      if isa(node, MCMCLogical)
        attr["shape"] = "diamond"
      elseif isa(node, MCMCStochastic)
        attr["shape"] = "ellipse"
      end
      if !any(node.monitor)
        attr["style"] = "filled"
        attr["fillcolor"] = "gray85"
      end
    else
      attr["shape"] = "box"
      attr["style"] = "filled"
      attr["fillcolor"] = "gray85"
    end
    str = str * string(
      "\t\"", v.key, "\" [",
      join(map(x -> "$(x[1])=\"$(x[2])\"", attr), ", "),
      "];\n"
    )
    for e in out_edges(v, g)
      t = target(e, g)
      str = str * "\t\t\"$(v.key)\" -> \"$(t.key)\";\n"
     end
  end
  str * "}\n"
end

function graph2dot(m::MCMCModel, filename::String)
  f = open(filename, "w")
  write(f, graph2dot(m))
  close(f)
end

function plot(m::MCMCModel)
  stream, process = writesto(`dot -Tx11`)
  write(stream, graph2dot(m))
  close(stream)
end

function tsort{T}(g::AbstractGraph{KeyVertex{T}, Edge{KeyVertex{T}}})
  V = topological_sort_by_dfs(g)
  map(v -> v.key, V)
end

function tsort(m::MCMCModel)
  tsort(graph(m))
end
