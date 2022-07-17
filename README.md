# pastel.lua
bring colors to lua

```lua
local pastel = require "colors" "truecolor"

print(pastel.colorize "<u b i #FF6961>foo</# u> <#6DCE80>bar</# i> <#779ECB>baz</# b> </>qux")
```
![image](https://user-images.githubusercontent.com/46825856/179404470-d430b7e3-82e4-417b-b016-8d041b97f51a.png)

### Docs

#### pastel(mode: `string`): `table`
Loads pastel in choosen mode
Avalible modes:
- truecolor
- 256-color
- ansi

#### colorize(str: `string`): `string`
Parses tags in string and returns it

#### Avaliable tags
- `<reset>, <r>`
- `<bold>, <b>`
- `<dim>, <light>, <l>`
- `<italic>, <i>`
- `<underline>, <u>`
- `<blink>, <bl>`
- `<rblink>, <rbl>`
- `<reverse>, <invert>, <rev>, <inv>`
- `<hide>, <h>`
- `<strike>, <s>`
- `<font_default>, <fd>`
- `<font(1-9)>, <f(1-9)>`
- `<gothic>, <fg>`
- `<double_underline>, <du>`
- `<black>, <bg_black>, <bright_black>`
- `<red>, <bg_red>, <bright_red>`
- `<green>, <bg_green>, <bright_green>`
- `<yellow>, <bg_yellow>, <bright_yellow>`
- `<blue>, <bg_blue>, <bright_blue>`
- `<magenta>, <bg_magenta>, <bright_magenta>`
- `<cyan>, <bg_cyan>, <bright_cyan>`
- `<white>, <bg_white>, <bright_white>`
- `<framed>, <fr>`
- `<encircled>, <ec>`
- `<overlined>, <ol>`
- `<hex(XXXXXX)>, #XXXXXX`
- `<bg_hex(XXXXXX)>, bg#XXXXXX`
- `<u_hex(XXXXXX)>, u#XXXXXX`
- `<rgb(xxx,xxx,xxx)>`
- `<bg_rgb(xxx,xxx,xxx)>`
- `<u_rgb(xxx,xxx,xxx)>`
