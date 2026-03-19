# super_mini_llm.nvim

Yet another Neovim AI plugin? 🤔

Yes. I wasn't satisfied with the existing options, mainly for the reason that they just offer too many features.
Features I'm never going to use. I use AI agents heavily, like Claude Code, or OpenAI Codex, and these work great when I
want a very intelligent agent handling a problem, looking up the context itself, etc.

However, sometimes I *just* want to edit the current file with an LLM. I don't need a bunch of crazy features, I don't
need an agent, I just want to send the buffer to the LLM and get back some output to replace it.

Well, that's what this plugin is for. There's two commands: `:LLM` and `:LLMConfig`. Very simple. `:LLM <prompt>` replaces
the whole buffer with the LLM's response. And `:LLMConfig` is for... basically everything else you need, ie.,
configuring the provider & model being used, changing the system prompt, etc.

## Requirements

- Neovim 0.10+
- `curl`

## Installation

Add the plugin directory to your runtimepath:

```lua
vim.opt.runtimepath:prepend("/path/to/super_mini_llm.nvim")

require('super_mini_llm').setup({
  api_key = os.getenv("ANTHROPIC_API_KEY"),
})
```

Or with a plugin manager like lazy.nvim:

```lua
{
  dir = "/path/to/super_mini_llm.nvim",
  config = function()
    require('super_mini_llm').setup({
      api_key = os.getenv("ANTHROPIC_API_KEY"),
    })
  end,
}
```

## Configuration

```lua
require('super_mini_llm').setup({
  provider = "anthropic",           -- which provider to use
  model = "claude-sonnet-4-6",      -- model to use (nil = provider default)
  api_key = "...",                  -- API key (string or function)
  system_prompt = nil,              -- optional additional system prompt
})
```

### API Key

The `api_key` option accepts a string or a function:

```lua
-- Direct string
api_key = os.getenv("ANTHROPIC_API_KEY"),

-- Function (useful for password managers)
api_key = function()
  return vim.trim(vim.fn.system("op read op://vault/item/credential"))
end,
```

## Commands

### :LLM {prompt}

Send text to the LLM with a prompt. The response replaces the original text.

```vim
" Replace entire buffer
:LLM add comments to this code

" Replace visual selection
:'<,'>LLM translate to french
```

### :LLMConfig

View or modify configuration.

```vim
:LLMConfig                  " Show current config
:LLMConfig model            " Show current model
:LLMConfig model <name>     " Set model
:LLMConfig provider         " Show current provider
:LLMConfig provider <name>  " Set provider
:LLMConfig list_models      " Fetch available models from API
```

## Adding Providers

Create a new file in `lua/super_mini_llm/providers/` with this structure:

```lua
local request = require("super_mini_llm.request")

local M = {}

M.name = "myprovider"
M.default_model = "default-model-name"
M.models = { "model-1", "model-2" }

function M.complete(opts, callback)
  -- opts: { text, prompt, system_prompt, model, api_key }
  -- callback: function(err, result)
end

function M.list_models(api_key, callback)
  -- callback: function(err, models)
end

return M
```

Then register it in `lua/super_mini_llm/providers/init.lua`:

```lua
M.register(require("super_mini_llm.providers.myprovider"))
```
