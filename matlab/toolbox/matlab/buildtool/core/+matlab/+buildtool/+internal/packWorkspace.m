function ws = packWorkspace()
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2022 The MathWorks, Inc.

ws = struct();
vars = evalin("caller", "who");
for i = 1:numel(vars)
    ws.(vars{i}) = evalin("caller", vars{i});
end
end