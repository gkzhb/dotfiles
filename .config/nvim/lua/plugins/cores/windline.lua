return {
  'windwp/windline.nvim',
  dependencies = { 'Mofiqul/vscode.nvim' },
  config = function()
    require('wline.airline')
  end,
}
