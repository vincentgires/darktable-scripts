local function apply_style(style_name, image)
  local style
  for i, s in ipairs(dt.styles) do
    if s.name == style_name then
      style = s
    end
  end
  dt.styles.apply(style, image)
end
