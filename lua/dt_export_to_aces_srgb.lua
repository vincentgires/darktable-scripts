-- TODO: add exif/metadata

dt = require 'darktable'

local FIND_EXT_PATTERN = '^.+(%..+)$'
local EXPORTED_EXT = '.jpg'

local export_path_widget = dt.new_widget('entry') {
  tooltip = 'target path to export file',
  text = dt.preferences.read('aces_export', 'export_path', 'string')}

local input_colorspace_label_widget = dt.new_widget('label') {
  label = 'input colorspace'}

local input_colorspace_name_widget = dt.new_widget('entry') {
  text = 'lin_rec2020',
  placeholder = 'colorspace'}

local output_colorspace_label_widget = dt.new_widget('label') {
  label = 'output colorspace'}

local output_colorspace_name_widget = dt.new_widget('entry') {
  text = 'out_srgb',
  placeholder = 'colorspace'}

local input_colorspace_widget = dt.new_widget('box'){
  orientation = 'horizontal',
  input_colorspace_label_widget,
  input_colorspace_name_widget}

local output_colorspace_widget = dt.new_widget('box'){
  orientation = 'horizontal',
  output_colorspace_label_widget,
  output_colorspace_name_widget}

local colorspace_widget = dt.new_widget('box'){
  orientation = 'vertical',
  input_colorspace_widget,
  output_colorspace_widget}

local look_name_widget = dt.new_widget('entry') {
  tooltip = 'ocio look name',
  placeholder = 'look',
  text = '',
  editable = false}

local use_look_widget = dt.new_widget('check_button') {
  label = 'use look',
  value = false,
  clicked_callback = function(self) look_name_widget.editable = self.value end}

local look_widget = dt.new_widget('box'){
  orientation = 'horizontal',
  use_look_widget,
  look_name_widget}

local export_widget = dt.new_widget('box'){
  orientation = 'vertical',
  colorspace_widget,
  look_widget,
  export_path_widget}

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

  -- add datetime to filename and set extension
  local datetime = string.sub(image.exif_datetime_taken, 1, 10) -- keep only yyyy:mm:dd
  datetime = string.gsub(datetime, ':', '') -- result is yyyymmdd
  local image_extension = string.match(image.filename, FIND_EXT_PATTERN)
  local output_filename = string.gsub(image.filename, image_extension, EXPORTED_EXT)
  local output_path = export_path_widget.text..'/'..datetime..'_'..output_filename

  -- convert exr image to jpeg
  local command = 'oiiotool ' .. filename .. ' -colorconvert ' .. input_colorspace_name_widget.text .. ' ' .. output_colorspace_name_widget.text
  if use_look_widget.value then command = command .. ' --ociolook ' .. look_name_widget.text end
  command = command .. ' --compression jpeg:95 -o ' .. output_path
  os.execute(command)

  -- set filmic module back
  apply_style('filmic aces srgb rrt preview', image)
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
  export_widget)
