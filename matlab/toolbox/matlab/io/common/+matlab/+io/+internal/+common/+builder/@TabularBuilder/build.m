function T = build(obj, varargin)
%TabularBuilder.build   Construct a table/timetable from the current
%   TabularBuilder options.
%
%   The number of variables provided as input must match the number of VariableNames
%   in the object.

%   Copyright 2022 The MathWorks, Inc.

    % Build the table.
    T = obj.Options.UnderlyingBuilder.build(varargin{:});
end
