dt = require 'darktable'

local import_path = dt.new_widget('entry') {
  tooltip = 'import folder'}

local function import_files_with_xmp()
  for filename in io.popen('ls ' .. import_path.text .. '/*.xmp'):lines() do
    local rawpath = string.gsub(filename, '.xmp', '')
    local image = dt.database.import(rawpath)
  end
end

local import_btn = dt.new_widget('button') {
  tooltip = 'import files with xmp',
  label = 'import',
  clicked_callback = import_files_with_xmp}

local webgallery_widget = dt.new_widget('box'){
  orientation = 'vertical',
  import_path,
  import_btn}

dt.register_lib('import_files', 'import files with xmp', true, true, {
  [dt.gui.views.lighttable] = {'DT_UI_CONTAINER_PANEL_LEFT_CENTER', 1},
}, webgallery_widget)
