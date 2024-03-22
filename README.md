# Harpoon Tabline

This plugin replicates the behavior of the tabline in the original version of the [Harpoon](github.com/ThePrimeagen/harpoon) plugin for the harpoon2 branch.

## Installation

First add harpoontabline as a dependency of harpoon:

```lua
{
    "ThePrimeagen/harpoon",
    dependencies = {
        "CWood-sdf/harpoontabline"
    }
},
```

Then add the following to your harpoon configuration:

```lua
require('harpoon').extend(require('harpoontabline').get())
```

## Configuration

Right now, there is no configuration available for this plugin, but it should be added in the coming days.

## Self Promotion

Check out my other plugins:

- [Spaceport](github.com/CWood-sdf/spaceport.nvim) — A plugin for getting to all of your projects as quickly as possible.
- [Pineapple](github.com/CWood-sdf/pineapple) — A plugin for managing your themes.
