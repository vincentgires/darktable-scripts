dt = require 'darktable'

local BLENDER_CONVERT_SCRIPT = os.getenv('BLENDER_USER_SCRIPTS')..'/templates_py/convert_image.py'

local export_path = dt.new_widget('entry') {
  tooltip = 'target path to export file',
  text = '',
  reset_callback = function(self) self.text = '' end
}

local function export_pre(storage, format, images, high_quality, extra_data)
  -- remove filmic module
  -- set format to linear exr
  -- NOTE: seems not possible with the current api
end

local function export_image(
    storage, image, format, filename,
    number, total, high_quality, extra_data)
  print('exporting '..image.filename..' 'tostring(number)..'/'..tostring(total))
  os.execute('blender --background --python '..BLENDER_CONVERT_SCRIPT..' -- -inputs '..filename..' -output '..export_path.text)
end

dt.register_storage('aces_export', 'export to aces srgb',
  export_image,
  nil, --finalize
  nil, --supported
  export_pre, --initialize
  dt.new_widget('box') {
    orientation='horizontal',
    dt.new_widget('label'){label = 'target'},
    export_path}
)
