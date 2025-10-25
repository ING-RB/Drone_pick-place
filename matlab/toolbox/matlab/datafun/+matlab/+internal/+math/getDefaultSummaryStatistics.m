function stats = getDefaultSummaryStatistics(X)
%getDefaultSummaryStatistics Return a list of the default statistics based
%   on the type of X.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2024 The MathWorks, Inc.

if isfloat(X) || isduration(X) || isdatetime(X)
    stats = {"nummissing", "min", "median", "max", "mean", "std"};
elseif isinteger(X)
    stats = {"nummissing", "min", "median", "max", "mean"};
elseif islogical(X)
    stats = {"true", "false"};
elseif isordinal(X)
    stats = {"nummissing", "min", "median", "max"};
elseif isstring(X) || iscellstr(X) || ischar(X) || iscategorical(X)
    stats = {"nummissing"};
else
    stats = {"nummissing", "min", "median", "max", "mean", "std"};
end
end