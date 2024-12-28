local M = {}

--- Determines if the current string ends with the paramater string given
--- @param s string
--- @param ending string
--- @return boolean
function M.ends_with(s, ending)
  return ending == "" or s:sub(-#ending) == ending
end

--- Gets extension from the string treated as a filename
--- @param s string
--- @return string extension Extension of the filename without the '.' (e.g. jpg)
function M.get_file_extension(s)
  return s:match("[^.]+$")
end

return M
