function tablePropertiesOffset = getTablePropertiesOffset(summaryInfo)
%getTablePropertiesOffset Get offset into per-variable table properties
%   Offset into tableProperties per-variable fields. Will be 0 for a table,
%   and 1 for a timetable. We need this offset because (print|emit)SummaryInfo
%   will have a summaryInfo entry for the RowTimes, but there are no
%   VariableUnits etc.

% Copyright 2019 The MathWorks, Inc.

if numel(summaryInfo) > 0 && ~isempty(summaryInfo{1}.RowLabelDescr)
    tablePropertiesOffset = 1;
else
    tablePropertiesOffset = 0;
end
end
