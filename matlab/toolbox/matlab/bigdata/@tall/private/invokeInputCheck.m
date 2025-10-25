function args = invokeInputCheck(fcnInfo, varargin)
%invokeInputCheck Check inputs from builtin code

% Copyright 2016-2022 The MathWorks, Inc.

args = varargin;
if ~isempty(fcnInfo.InputConstraint)
    % constraint might be 'table', or 'numeric logical' etc.
    constraint = strsplit(fcnInfo.InputConstraint);
    % do we support tabular math (i.e. need to recurse into tables instead
    % of treating as a type in their own right)?
    [args{:}] = tall.validateType(varargin{:}, fcnInfo.Name, ...
        constraint, 1:numel(varargin), ...
        fcnInfo.AllowTabularMaths);
end
end
