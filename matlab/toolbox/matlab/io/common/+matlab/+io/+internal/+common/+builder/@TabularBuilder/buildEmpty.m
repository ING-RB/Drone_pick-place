function T = buildEmpty(obj)
%TabularBuilder.buildEmpty   Construct an empty table/timetable from the
%   current TabularBuilder options.
%
%   If VariableTypes is supplied, then the generated empty table/timetable contains empty
%   data of the supplied type in each variable.

%   Copyright 2022 The MathWorks, Inc.

    % Call into the underlying builder to do this.
    T = obj.Options.UnderlyingBuilder.buildEmpty();
end
