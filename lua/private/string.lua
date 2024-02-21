--- Determines if the current string ends with the paramater string given
--- @param ending string
--- @return boolean
function string:ends_with(ending)
  return ending == "" or self:sub(- #ending) == ending
end

--- Gets extension from the string treated as a filename
--- @return string extension Extension of the filename without the '.' (e.g. jpg)
function string:get_file_extension()
  return self:match("[^.]+$")
end
