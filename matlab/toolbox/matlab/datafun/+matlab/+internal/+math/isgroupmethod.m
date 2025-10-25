function tf = isgroupmethod(methods)
% ISGROUPMETHOD Determine if methods is a valid method specification
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.

if isstring(methods)
    methods = num2cell(methods);
elseif ~iscell(methods)
    methods = {methods};
end

if isempty(methods)
    tf = false;
elseif isa(methods{1},"function_handle")
    tf = true;
else
    if (ischar(methods{1}) && isrow(methods{1})) || isstring(methods{1})
        tf = any(startsWith(["all", "mean", "sum", "min", "max", "range", ...
            "median", "mode", "var", "std", "nummissing", "nnz", "numunique"],string(methods{1}),"IgnoreCase",true));
    else
        tf = false;
    end
end