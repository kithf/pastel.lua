local s, o = pcall(require, "bit")
if not s then s, o = pcall(require, "bit32") end
local bit = o 
if not bit then error "bit library not found" end
local band, rshift, lshift, bnot, bor = bit.band, bit.rshift, bit.lshift, bit.bnot, bit.bor
local sfmt, ssub, sgsub, smatch, slow = 
  string.format, string.sub, string.gsub, string.match, string.lower
local tins, tcon = table.insert, table.concat
local abs = math.abs
local tonumber = tonumber
local ipairs = ipairs
local to_rgb = function(col)
  return band(rshift(col, 16), 0xFF),
        band(rshift(col, 8), 0xFF),
        band(col, 0xFF)
end
local diff = function(col1, col2)
  local r1, g1, b1 = to_rgb(col1)
  local r2, g2, b2 = to_rgb(col2)
  return abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
end

-- https://en.wikipedia.org/wiki/ANSI_escape_code
local map = {
	reset = 0, r = 0,
  bold = 1, b = 1,
  dim = 2, light = 2, l = 2,
  italic = 3, i = 3,
  underline = 4, u = 4,
  blink = 5, bl = 5,
  rblink = 6, rbl = 6,
  reverse = 7, invert = 7, inv = 7, rev = 7,
  hide = 8, h = 8,
  strike = 9, s = 9,
  font_default = 10, fd = 10,
  font_1 = 11, f1 = 11,
  font_2 = 12, f2 = 12,
  font_3 = 13, f3 = 13,
  font_4 = 14, f4 = 14,
  font_5 = 15, f5 = 15,
  font_6 = 16, f6 = 16,
  font_7 = 17, f7 = 17,
  font_8 = 18, f8 = 18,
  font_9 = 19, f9 = 19,
  gothic = 20, fg = 20,
  double_underline = 21, du = 21,
  black = 30, bg_black = 40,
  red = 31, bg_red = 41,
  green = 32, bg_green = 42,
  yellow = 33, bg_yellow = 43,
  blue = 34, bg_blue = 44,
  magenta = 35, bg_magenta = 45,
  cyan = 36, bg_cyan = 46,
  white = 37, bg_white = 47,
  bright_black = 90, bg_bright_black = 100,
  bright_red = 91, bg_bright_red = 101,
  bright_green = 92, bg_bright_green = 102,
  bright_yellow = 93, bg_bright_yellow = 103,
  bright_blue = 94, bg_bright_blue = 104,
  bright_magenta = 95, bg_bright_magenta = 105,
  bright_cyan = 96, bg_bright_cyan = 106,
  bright_white = 97, bg_bright_white = 107,
  hex = 38, ["#"] = 38,
  rgb = 38,
  bg_hex = 48, ["bg#"] = 48,
  bg_rgb = 48,
  framed = 51, fr = 51,
  encircled = 52, ec = 52,
  overlined = 53, ol = 53,
  u_hex = 58, ["u#"] = 58,
  u_rgb = 58,
}

local not_map = {
  reset = 0, r = 0, 
  bold = 22, b = 22,
  dim = 22, light = 22, l = 22,
  italic = 23, i = 23,
  underline = 24, u = 24,
  blink = 25, bl = 25,
  rblink = 25, rbl = 25,
  reverse = 27, invert = 27, inv = 27, rev = 27,
  hide = 28, h = 28,
  reveal = 28, revl = 28,
  strike = 29, s = 29,
  font_default = 22, fd = 22,
  font_1 = 22, f1 = 22,
  font_2 = 22, f2 = 22,
  font_3 = 22, f3 = 22,
  font_4 = 22, f4 = 22,
  font_5 = 22, f5 = 22,
  font_6 = 22, f6 = 22,
  font_7 = 22, f7 = 22,
  font_8 = 22, f8 = 22,
  font_9 = 22, f9 = 22,
  gothic = 22, fg = 22,
  double_underline = 24, du = 24,
  black = 39, bg_black = 49,
  red = 39, bg_red = 49,
  green = 39, bg_green = 49,
  yellow = 39, bg_yellow = 49,
  blue = 39, bg_blue = 49,
  magenta = 39, bg_magenta = 49,
  cyan = 39, bg_cyan = 49,
  white = 39, bg_white = 49,
  bright_black = 39, bg_bright_black = 49,
  bright_red = 39, bg_bright_red = 49,
  bright_green = 39, bg_bright_green = 49,
  bright_yellow = 39, bg_bright_yellow = 49,
  bright_blue = 39, bg_bright_blue = 49,
  bright_magenta = 39, bg_bright_magenta = 49,
  bright_cyan = 39, bg_bright_cyan = 49,
  bright_white = 39, bg_bright_white = 49,
  color  = 39, c = 39, ["#"] = 39, hex = 39, rgb = 39,
  bg_color = 49, bc = 49, ["bg#"] = 49, bg_hex = 39, bg_rgb = 49,
  u_color = 59, uc = 59, ["u#"] = 59, u_hex = 39, u_rgb = 59,
  framed = 54, encircled = 54, fr = 54, ec = 54,
  overlined = 55, ol = 55,
}

-- <rgb(1, 2, 3) underline>foo</rgb underline>
local load_truecolor = function()
  local parse_tags = function(str)
    local s = sgsub(str, "%b<>", function(tags)
      if tags == "</>" then return "\27[0m" end
      local _not = ssub(tags, 2, 2) == "/"
      tags = ssub(tags, _not and 3 or 2)
      local map = _not and not_map or map

      local buf = {}
  
      local i = 1
      local tag = ""
      while i <= #tags do
        local c = ssub(tags, i, i)
        
        if c == " " or c == ">" then
          tag = slow(tag)
          if ssub(tag, 1,3) == "rgb" then
            local r, g, b = smatch(tag, "rgb%((%d+),(%d+),(%d+)%)")
            tins(buf, "\27[38;2;"..r..";"..g..";"..b.."m")
          elseif ssub(tag,1,6) == "bg_rgb" then
            local r, g, b = smatch(tag, "bg_rgb%((%d+),(%d+),(%d+)%)")
            tins(buf, "\27[48;2;"..r..";"..g..";"..b.."m")
          elseif ssub(tag,1,5) == "u_rgb" then
            local r, g, b = smatch(tag, "u_rgb%((%d+),(%d+),(%d+)%)")
            tins(buf, "\27[58;2;"..r..";"..g..";"..b.."m")
          elseif ssub(tag,1,1) == "#" then
            local r, g, b = to_rgb(tonumber(ssub(tag,2), 16))
            tins(buf, "\27[38;2;"..r..";"..g..";"..b.."m")
          elseif ssub(tag,1,3) == "bg#" then
            local r, g, b = to_rgb(tonumber(ssub(tag,4), 16))
            tins(buf, "\27[48;2;"..r..";"..g..";"..b.."m")
          elseif ssub(tag,1,2) == "u#" then
            local r, g, b = to_rgb(tonumber(ssub(tag,3), 16))
            tins(buf, "\27[58;2;"..r..";"..g..";"..b.."m")
          else
            local n = map[tag]
            if n then
              tins(buf, "\27["..n.."m")
            end
          end

          i = i + 1
          tag = ""
        else
          tag = tag..c
          i = i + 1
        end
      end

      return tcon(buf)
    end)
    return s
  end
  
  local colorize = function(str)
    return parse_tags("</>"..str.."</>")
  end

  return {
    colorize = colorize,
    parse_tags = parse_tags,
  }
end

local load_256 = function()
  local colors = {
    [1]   = 0x000000,	[2]   = 0x800000,	[3]   = 0x008000,	[4]   = 0x808000,
    [5]   = 0x000080,	[6]   = 0x800080,	[7]   = 0x008080,	[8]   = 0xc0c0c0,
    [9]   = 0x808080,	[10]  = 0xff0000,	[11]  = 0x00ff00,	[12]  = 0xffff00,
    [13]  = 0x0000ff,	[14]  = 0xff00ff,	[15]  = 0x00ffff,	[16]  = 0x000000,
    [17]  = 0x00005f,	[18]  = 0x000087,	[19]  = 0x0000af,	[20]  = 0x0000d7,
    [21]  = 0x0000ff,	[22]  = 0x005f00,	[23]  = 0x005f5f,	[24]  = 0x005f87,
    [25]  = 0x005faf,	[26]  = 0x005fd7,	[27]  = 0x005fff,	[28]  = 0x008700,
    [29]  = 0x00875f,	[30]  = 0x008787,	[31]  = 0x0087af,	[32]  = 0x0087d7,
    [33]  = 0x0087ff,	[34]  = 0x00af00,	[35]  = 0x00af5f,	[36]  = 0x00af87,
    [37]  = 0x00afaf,	[38]  = 0x00afd7,	[39]  = 0x00afff,	[40]  = 0x00d700,
    [41]  = 0x00d75f,	[42]  = 0x00d787,	[43]  = 0x00d7af,	[44]  = 0x00d7d7,
    [45]  = 0x00d7ff,	[46]  = 0x00ff00,	[47]  = 0x00ff5f,	[48]  = 0x00ff87,
    [49]  = 0x00ffaf,	[50]  = 0x00ffd7,	[51]  = 0x00ffff,	[52]  = 0x5f0000,
    [53]  = 0x5f005f,	[54]  = 0x5f0087,	[55]  = 0x5f00af,	[56]  = 0x5f00d7,
    [57]  = 0x5f00ff,	[58]  = 0x5f5f00,	[59]  = 0x5f5f5f,	[60]  = 0x5f5f87,
    [61]  = 0x5f5faf,	[62]  = 0x5f5fd7,	[63]  = 0x5f5fff,	[64]  = 0x5f8700,
    [65]  = 0x5f875f,	[66]  = 0x5f8787,	[67]  = 0x5f87af,	[68]  = 0x5f87d7,
    [69]  = 0x5f87ff,	[70]  = 0x5faf00,	[71]  = 0x5faf5f,	[72]  = 0x5faf87,
    [73]  = 0x5fafaf,	[74]  = 0x5fafd7,	[75]  = 0x5fafff,	[76]  = 0x5fd700,
    [77]  = 0x5fd75f,	[78]  = 0x5fd787,	[79]  = 0x5fd7af,	[80]  = 0x5fd7d7,
    [81]  = 0x5fd7ff,	[82]  = 0x5fff00,	[83]  = 0x5fff5f,	[84]  = 0x5fff87,
    [85]  = 0x5fffaf,	[86]  = 0x5fffd7,	[87]  = 0x5fffff,	[88]  = 0x870000,
    [89]  = 0x87005f,	[90]  = 0x870087,	[91]  = 0x8700af,	[92]  = 0x8700d7,
    [93]  = 0x8700ff,	[94]  = 0x875f00,	[95]  = 0x875f5f,	[96]  = 0x875f87,
    [97]  = 0x875faf,	[98]  = 0x875fd7,	[99]  = 0x875fff,	[100] = 0x878700,
    [101] = 0x87875f,	[102] = 0x878787,	[103] = 0x8787af,	[104] = 0x8787d7,
    [105] = 0x8787ff,	[106] = 0x87af00,	[107] = 0x87af5f,	[108] = 0x87af87,
    [109] = 0x87afaf,	[110] = 0x87afd7,	[111] = 0x87afff,	[112] = 0x87d700,
    [113] = 0x87d75f,	[114] = 0x87d787,	[115] = 0x87d7af,	[116] = 0x87d7d7,
    [117] = 0x87d7ff,	[118] = 0x87ff00,	[119] = 0x87ff5f,	[120] = 0x87ff87,
    [121] = 0x87ffaf,	[122] = 0x87ffd7,	[123] = 0x87ffff,	[124] = 0xaf0000,
    [125] = 0xaf005f,	[126] = 0xaf0087,	[127] = 0xaf00af,	[128] = 0xaf00d7,
    [129] = 0xaf00ff,	[130] = 0xaf5f00,	[131] = 0xaf5f5f,	[132] = 0xaf5f87,
    [133] = 0xaf5faf,	[134] = 0xaf5fd7,	[135] = 0xaf5fff,	[136] = 0xaf8700,
    [137] = 0xaf875f,	[138] = 0xaf8787,	[139] = 0xaf87af,	[140] = 0xaf87d7,
    [141] = 0xaf87ff,	[142] = 0xafaf00,	[143] = 0xafaf5f,	[144] = 0xafaf87,
    [145] = 0xafafaf,	[146] = 0xafafd7,	[147] = 0xafafff,	[148] = 0xafd700,
    [149] = 0xafd75f,	[150] = 0xafd787,	[151] = 0xafd7af,	[152] = 0xafd7d7,
    [153] = 0xafd7ff,	[154] = 0xafff00,	[155] = 0xafff5f,	[156] = 0xafff87,
    [157] = 0xafffaf,	[158] = 0xafffd7,	[159] = 0xafffff,	[160] = 0xd70000,
    [161] = 0xd7005f,	[162] = 0xd70087,	[163] = 0xd700af,	[164] = 0xd700d7,
    [165] = 0xd700ff,	[166] = 0xd75f00,	[167] = 0xd75f5f,	[168] = 0xd75f87,
    [169] = 0xd75faf,	[170] = 0xd75fd7,	[171] = 0xd75fff,	[172] = 0xd78700,
    [173] = 0xd7875f,	[174] = 0xd78787,	[175] = 0xd787af,	[176] = 0xd787d7,
    [177] = 0xd787ff,	[178] = 0xd7af00,	[179] = 0xd7af5f,	[180] = 0xd7af87,
    [181] = 0xd7afaf,	[182] = 0xd7afd7,	[183] = 0xd7afff,	[184] = 0xd7d700,
    [185] = 0xd7d75f,	[186] = 0xd7d787,	[187] = 0xd7d7af,	[188] = 0xd7d7d7,
    [189] = 0xd7d7ff,	[190] = 0xd7ff00,	[191] = 0xd7ff5f,	[192] = 0xd7ff87,
    [193] = 0xd7ffaf,	[194] = 0xd7ffd7,	[195] = 0xd7ffff,	[196] = 0xff0000,
    [197] = 0xff005f,	[198] = 0xff0087,	[199] = 0xff00af,	[200] = 0xff00d7,
    [201] = 0xff00ff,	[202] = 0xff5f00,	[203] = 0xff5f5f,	[204] = 0xff5f87,
    [205] = 0xff5faf,	[206] = 0xff5fd7,	[207] = 0xff5fff,	[208] = 0xff8700,
    [209] = 0xff875f,	[210] = 0xff8787,	[211] = 0xff87af,	[212] = 0xff87d7,
    [213] = 0xff87ff,	[214] = 0xffaf00,	[215] = 0xffaf5f,	[216] = 0xffaf87,
    [217] = 0xffafaf,	[218] = 0xffafd7,	[219] = 0xffafff,	[220] = 0xffd700,
    [221] = 0xffd75f,	[222] = 0xffd787,	[223] = 0xffd7af,	[224] = 0xffd7d7,
    [225] = 0xffd7ff,	[226] = 0xffff00,	[227] = 0xffff5f,	[228] = 0xffff87,
    [229] = 0xffffaf,	[230] = 0xffffd7,	[231] = 0xffffff,	[232] = 0x080808,
    [233] = 0x121212,	[234] = 0x1c1c1c,	[235] = 0x262626,	[236] = 0x303030,
    [237] = 0x3a3a3a,	[238] = 0x444444,	[239] = 0x4e4e4e,	[240] = 0x585858,
    [241] = 0x626262,	[242] = 0x6c6c6c,	[243] = 0x767676,	[244] = 0x808080,
    [245] = 0x8a8a8a,	[246] = 0x949494,	[247] = 0x9e9e9e,	[248] = 0xa8a8a8,
    [249] = 0xb2b2b2,	[250] = 0xbcbcbc,	[251] = 0xc6c6c6,	[252] = 0xd0d0d0,
    [253] = 0xdadada,	[254] = 0xe4e4e4,	[255] = 0xeeeeee,	[256] = 0xf8f8f8,
  }

  local convert = function(hexcolor)
    local diffs, min = {}, 999999
    for k, col in ipairs(colors) do
      local d = diff(col, hexcolor)
      diffs[d] = k
      if d < min then min = d end
    end
    return diffs[min]
  end
  local parse_tags = function(str)
    local s = sgsub(str, "%b<>", function(tags)
      if tags == "</>" then return "\27[0m" end
      local _not = ssub(tags, 2, 2) == "/"
      tags = ssub(tags, _not and 3 or 2)
      local map = _not and not_map or map

      local buf = {}
  
      local i = 1
      local tag = ""
      while i <= #tags do
        local c = ssub(tags, i, i)

        if c == " " or c == ">" then
          tag = slow(tag)
          if ssub(tag, 1,3) == "rgb" then
            local r, g, b = smatch(tag, "rgb%((%d+),(%d+),(%d+)%)")
            local col = convert(tonumber(sfmt("%02x%02x%02x", r, g, b), 16))
            tins(buf, sfmt("\27[38;5;%dm", col))
          elseif ssub(tag, 1, 6) == "bg_rgb" then
            local r, g, b = smatch(tag, "bg_rgb%((%d+),(%d+),(%d+)%)")
            local col = convert(tonumber(sfmt("%02x%02x%02x", r, g, b), 16))
            tins(buf, sfmt("\27[48;5;%dm", col))
          elseif ssub(tag, 1, 5) == "u_rgb" then
            local r, g, b = smatch(tag, "u_rgb%((%d+),(%d+),(%d+)%)")
            local col = convert(tonumber(sfmt("%02x%02x%02x", r, g, b), 16))
            tins(buf, smt("\27[58;5;%dm", col))
          elseif ssub(tag, 1,1) == "#" then
            local col = convert(tonumber(ssub(tag, 2), 16))
            tins(buf, sfmt("\27[38;5;%dm", col))
          elseif ssub(tag, 1, 3) == "bg#" then
            local col = convert(tonumber(ssub(tag, 4), 16))
            tins(buf, sfmt("\27[48;5;%dm", col))
          elseif ssub(tag, 1, 2) == "u#" then
            local col = convert(tonumber(ssub(tag, 3), 16))
            tins(buf, sfmt("\27[58;5;%dm", col))
          else
            local n = map[tag]
            if n then
              tins(buf, "\27["..n.."m")
            end
          end

          i = i + 1
          tag = ""
        else
          tag = tag .. c
          i = i + 1
        end
      end

      return tcon(buf)
    end)
    return s
  end

  local colorize = function(str)
    return parse_tags(sfmt("</>%s</>", str))
  end

  return {
    colorize = colorize,
    parse_tags = parse_tags,
  }
end

local load_ansi = function()
  local parse_tags = function(str)
    local s = sgsub(str, "%b<>", function(tags)
      if tags == "</>" then return "\27[0m" end
      local _not = ssub(tags, 2, 2) == "/"
      tags = ssub(tags, _not and 3 or 2)
      local map = _not and not_map or map

      local buf = {}
  
      local i = 1
      local tag = ""
      while i <= #tags do
        local c = ssub(tags, i, i)

        if c == " " or c == ">" then
          tag = slow(tag)
          -- unsupported tags
          if ssub(tag, 1,3) == "rgb" then
            tins(buf, "")
          elseif ssub(tag, 1, 6) == "bg_rgb" then
            tins(buf, "")
          elseif ssub(tag, 1, 5) == "u_rgb" then
            tins(buf, "")
          elseif ssub(tag, 1,1) == "#" then
            tins(buf, "")
          elseif ssub(tag, 1, 3) == "bg#" then
            tins(buf, "")
          elseif ssub(tag, 1, 2) == "u#" then
            tins(buf, "")
          else
            local n = map[tag]
            if n then
              tins(buf, "\27["..n.."m")
            end
          end

          i = i + 1
          tag = ""
        else
          tag = tag .. c
          i = i + 1
        end
      end

      return tcon(buf)
    end)
    return s
  end

  local colorize = function(str)
    return parse_tags(sfmt("</>%s</>", str))
  end

  return {
    colorize = colorize,
    parse_tags = parse_tags,
  }
end

return function(MODE)
  if MODE == "truecolor" then
    return load_truecolor()
  elseif MODE == "256-color" then
    return load_256()
  end
    
  return load_ansi()
end
