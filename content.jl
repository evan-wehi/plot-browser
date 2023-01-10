

@enum ContentType HTML Image

abstract type Content end
function getContentData(c::Content)::String 
  error("No data for $(c)")
end
function contentType(::Content)::ContentType
  error("No content type for $(c)")
end

struct NoContent <: Content 
  why::String
end
getContentData(nc::NoContent)::String = "<div>Unable to display: $(nc.why)</div>"
contentType(::NoContent) = HTML

struct MissingContent <: Content end
function getContentData(::MissingContent)::String 
  fn = "assets/broken-image.png"
  s = read(fn)
  return "data:image/png;base64," * base64encode(s)
end
contentType(::MissingContent) = Image

struct HTMLContent <: Content
  data::String
end
getContentData(h::HTMLContent)::String = h.data
contentType(::HTMLContent) = HTML

struct ImageContent <: Content
  data::String
end
getContentData(i::ImageContent)::String = i.data
contentType(::ImageContent) = Image

function contentFromFile(fn::String)
  bits = split(fn, ".")
  if length(bits) < 2
    return NoContent("unsupported file")
  end

  ext = lowercase(bits[end])

  if ext == "html"
    return HTMLContent("data:text/html;base64," * base64encode(read(fn)))
  end

  if ext == "png"
    return ImageContent("data:image/png;base64," * base64encode(read(fn)))
  end

  if ext == "jpg" || ext == "jpeg"
    return ImageContent("data:image/png;base64," * base64encode(read(fn)))
  end

  return NoContent("unsupported file")
end
