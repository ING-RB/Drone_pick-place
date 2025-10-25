function throwIfGraphics(x, childType)
% Guard against invalid graphics parents. This should be used after a call
% to axescheck to guard against figures etc being passsed as the first
% input to a plotting function.
%
% CHILDTYPE should be the name of the class that we are attempting to assign to
% this parent, e.g. "Line" for plot, scatter,etc.

% Copyright 2018 The MathWorks, Inc.

if ~istall(x) && isobject(x) && any(isgraphics(x))
    err = MException("MATLAB:handle_graphics:exceptions:HandleGraphicsException", ...
        getString(message("MATLAB:HandleGraphics:hgError", childType, shortname(x))));
    throwAsCaller(err);
end



function name = shortname(x)
% Extract just the trailing part of a fully scoped name (e.g. 
% shortname("matlab.ui.Figure") == "Figure")
name = regexprep(class(x), '.*\.', '');