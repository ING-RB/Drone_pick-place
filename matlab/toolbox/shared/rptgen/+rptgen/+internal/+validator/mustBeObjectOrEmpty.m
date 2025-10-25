function tf = mustBeObjectOrEmpty(value,class)
if isempty(value)
    tf = true;
else
    if isa(value,class)
        tf = true;
    else
        tf = false;
    end
end
end

