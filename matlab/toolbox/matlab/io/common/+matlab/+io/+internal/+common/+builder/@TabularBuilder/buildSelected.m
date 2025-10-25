function T = buildSelected(obj, varargin)
%TabularBuilder.buildSelected   Construct a table/timetable from the current
%   TabularBuilder options.
%
%   Unlike TabularBuilder.build(), you only have to specify selected
%   variables in the input to this function.
%
%   So the number of input variables should match the number of
%   SelectedVariableNames/SelectedVariableIndices.
%
%   NOTE: SelectedVariableIndices isn't necessarily in ascending order!
%   Make sure that your inputs are in the same order as
%   SelectedVariableIndices.

%   Copyright 2022 The MathWorks, Inc.

    % Call into the underlying builder to do this.
    T = obj.Options.UnderlyingBuilder.buildSelected(varargin{:});
end
