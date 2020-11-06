-- TODO: add exif/metadata

dt = require 'darktable'

local FIND_EXT_PATTERN = '^.+(%..+)$'
local EXPORTED_EXT = '.jpg'

local export_path_widget = dt.new_widget('entry') {
  tooltip = 'target path to export file',
  text = dt.preferences.read('ocio_export', 'export_path', 'string')}

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
  text = dt.preferences.read('ocio_export', 'look', 'string'),
  editable = false}

local use_look_widget = dt.new_widget('check_button') {
  label = 'use look',
  value = dt.preferences.read('ocio_export', 'use_look', 'bool'),
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

local function table_length(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

local function build_json_data(tags, exifs)
  local result = '{'

  -- tags
  result = result..'"tags"'..': ['
  for i, tag in ipairs(tags) do
    result = result..'"'..tag..'"'
    if i < #tags then
      result = result..', '
    end
  end
  result = result..']'

  result = result..', ' -- tags/exifs separator

  -- exifs
  result = result..'"exifs"'..': {'
  local count = 1
  for k, v in pairs(exifs) do
    local value
    if type(v) == 'number' then
      value = v
    elseif type(v) == 'string' then
      value = string.format('%q', v)
    end
    result = result..'"'..k..'": '..value
    if count < table_length(exifs) then
      result = result..', '
    end
    count = count + 1
  end
  result = result..'}'

  return result..'}'
end

local function export_image(
    storage, image, format, filename,
    number, total, high_quality, extra_data)
  print('exporting: '..image.filename..' '..tostring(number)..'/'..tostring(total))

  -- add datetime to filename and set extension
  local datetime = string.sub(image.exif_datetime_taken, 1, 10) -- keep only yyyy:mm:dd
  datetime = string.gsub(datetime, ':', '') -- result is yyyymmdd
  local image_extension = string.match(image.filename, FIND_EXT_PATTERN)
  local output_filename = string.gsub(image.filename, image_extension, EXPORTED_EXT)
  local output_path = export_path_widget.text..'/'..datetime..'_'..output_filename

  -- convert exr image to jpeg
  local command = 'oiiotool ' .. string.format('%q', filename) .. ' --colorconvert ' .. string.format('%q', input_colorspace_name_widget.text) .. ' ' .. string.format('%q', output_colorspace_name_widget.text)
  if use_look_widget.value then command = command .. ' --ociolook ' .. string.format('%q', look_name_widget.text) end
  command = command .. ' --compression jpeg:95 -o ' .. string.format('%q', output_path)
  print('command: ' .. command)
  os.execute(command)

  -- tags
  local tags = {}
  for _, tag in ipairs(dt.tags.get_tags(image)) do
    tag = tostring(tag)
    if not string.find(tag, 'darktable') then
      table.insert(tags, tag)
    end
  end

  -- exifs
  local exifs = {
    maker=image.exif_maker,
    model=image.exif_model,
    lens=image.exif_lens,
    aperture=image.exif_aperture,
    exposure=image.exif_exposure,
    focal_length=image.exif_focal_length,
    iso=image.exif_iso,
    datetime_taken=image.exif_datetime_taken,
    focus_distance=image.exif_focus_distance,
    crop=image.exif_crop}

  -- export json file with tags and exifs
  local data = build_json_data(tags, exifs)
  local json_path = output_path .. '.json'
  local file = io.open(json_path, 'w+')
  file:write(data)
  file:close()

  -- delete exr file
  os.remove(filename)

end

dt.preferences.register(
  'ocio_export', 'export_path', 'string',
  'ocio export: default export folderpath',
  'default export location',
  '/home/'..os.getenv('USER'))

dt.preferences.register(
  'ocio_export', 'use_look', 'bool',
  'ocio export: default use look option',
  'default use look checkbox',
  false)

dt.preferences.register(
  'ocio_export', 'look', 'string',
  'ocio export: default look option',
  'default look option',
  '')

dt.register_storage('ocio_export', 'export with ocio config',
  export_image, -- store
  nil, --finalize
  nil, --supported
  nil, --initialize
  export_widget)
