function tf = isCharRowVector(text)
    tf = ischar(text) && (isrow(text) || isequal(size(text),[0 0]));
end
