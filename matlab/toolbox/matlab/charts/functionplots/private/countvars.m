function n=countvars(outer)
% helper function: count the "visible" variables in fplot/fsurf/... input

% Copyright 2015-2022 The MathWorks, Inc.
    n = numel(symvarMulti(outer));
end

function vars = symvarMulti(c)
    if iscell(c)
        vars = cellfun(@symvarMulti, c, 'UniformOutput', false);
        vars = reshape(unique([vars{:}]),1,[]);
    elseif ischar(c) && isvarname(c) && (exist(c,'builtin') || exist(c,'file'))
        vars = {};
    elseif ischar(c) || isstring(c) || isa(c,"sym")
        vars = reshape(symvar(c),1,[]);
    else
        vars = {};
    end
end
