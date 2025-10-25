function tf = isTaskName(name)
% This function is unsupported and might change or be removed without 
% notice in a future version.

%   Copyright 2024 The MathWorks, Inc.

arguments
    name string
end

tf = false(size(name));
for i = 1:numel(name)
    tf(i) = isTaskNameElement(name(i));
end
end

function tf = isTaskNameElement(name)
segments = split(name, ":");
tf = all(arrayfun(@isTaskNameSegment, segments));
end

function tf = isTaskNameSegment(segment)
allowedChars = "a-zA-Z0-9._-";
tf = strlength(segment) > 0 ...
    && ~startsWith(segment, "-") ...
    && ~isempty(regexp(segment,"^["+allowedChars+"]+$","once"));
end