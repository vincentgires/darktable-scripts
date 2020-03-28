dt = require 'darktable'

local BLENDER_CONVERT_SCRIPT = os.getenv('BLENDER_USER_SCRIPTS')..'/templates_py/convert_image.py'

local export_path = dt.new_widget('entry') {
  tooltip = 'target path to export file',
  text = dt.preferences.read('aces_export', 'export_path', 'string'),
  reset_callback = function(self) self.text = '' end
}

local function apply_style(style_name, image)
  local style
  for i, s in ipairs(dt.styles) do
    if s.name == style_name then
      style = s
    end
  end
  dt.styles.apply(style, image)
end

local function export_pre(storage, format, images, high_quality, extra_data)
  -- remove filmic module
  -- set format to linear exr (TODO)
  for _, image in ipairs(images) do
    apply_style('filmic off', image)
  end
end

local function export_image(
    storage, image, format, filename,
    number, total, high_quality, extra_data)
  print('exporting '..image.filename..' '..tostring(number)..'/'..tostring(total))

  -- TODO: add datetime to filename
  print('-----------'..image.exif_datetime_taken)

  -- convert exr image to jpeg
  os.execute('blender --background --python '..BLENDER_CONVERT_SCRIPT..' -- -inputs '..filename..' -output '..export_path.text)

  -- set filmic module back
  apply_style('filmic aces srgb preview2', image)
end

dt.preferences.register(
  'aces_export', 'export_path',
  'string', 'aces export: default export folderpath',
  'default export location',
  '/home/'..os.getenv('USER'))

dt.register_storage('aces_export', 'export to aces srgb',
  export_image, -- store
  nil, --finalize
  nil, --supported
  export_pre, --initialize
  dt.new_widget('box') {
    orientation='horizontal',
    dt.new_widget('label'){label = 'target'},
    export_path}
)
