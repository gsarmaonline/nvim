from pynvim import attach
nvim = attach('socket', path='/tmp/nvim-socket')
buffer = nvim.current.buffer # Get the current buffer
buffer[0] = 'replace first line'
buffer[:] = ['replace whole buffer']
nvim.command('vsplit')
nvim.windows[1].width = 10
nvim.vars['global_var'] = [1, 2, 3]
nvim.eval('g:global_var')
