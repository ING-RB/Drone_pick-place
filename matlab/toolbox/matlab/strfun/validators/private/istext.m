function tf = istext(text)
    tf = isCharRowVector(text) || isstring(text) || ...
         iscell(text) && matlab.internal.datatypes.isCharStrings(text);
end
