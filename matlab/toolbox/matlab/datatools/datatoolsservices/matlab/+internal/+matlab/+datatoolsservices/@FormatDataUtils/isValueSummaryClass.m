% Returns true if this variable displays as a value summary

% Copyright 2015-2024 The MathWorks, Inc.

function result = isValueSummaryClass(className)
    valueSummaryClasses = {'table', 'categorical', 'dataset', 'cell', 'struct', 'object', 'nominal', 'ordinal', 'datetime', 'duration', 'calendarDuration'};
    result = any(strcmp(valueSummaryClasses, className));
end
