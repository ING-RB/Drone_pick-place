function choices = tableVariablesForTabCompletion(tbl, options)
% This is an undocumented function and may be removed in a future release.

%  This is a helper
%  function for tab completion for table support. It returns variables from
%  tbl, optionally including the first dimension name (which represents
%  either the row names or row times).

%   Copyright 2021-2022 The MathWorks, Inc.

arguments
    % Either a table (tabular) or a vector of objects with a SourceTable
    % property.
    tbl

    % Should the first dimension name (row names) from a regular table be
    % included in the list of results? These are cellstr, so they don't
    % work in most places.
    options.IncludeRowNames (1,1) logical = false

    % Should the first dimension name (row times) from a timetable be
    % included in the list of results?
    options.IncludeRowTimes (1,1) logical = true
end

choices = {};

if istabular(tbl)
    choices = tbl.Properties.VariableNames;
    if (options.IncludeRowNames && isa(tbl, 'table') && ~isempty(tbl.Properties.RowNames)) ...
            || (options.IncludeRowTimes && isa(tbl, 'timetable'))
        choices = [tbl.Properties.DimensionNames(1) tbl.Properties.VariableNames];
    end
elseif all(isprop(tbl, 'SourceTable'),'all')
    % A vector of objects might be passed in and if they all have
    % SourceTable property, return the common varaibles for all of them.
    % This is used for tab completion for the 'set' command.
    args = namedargs2cell(options);
    choices = matlab.graphics.chart.internal.tableVariablesForTabCompletion(...
        tbl(1).SourceTable, args{:});

    for i = 2:numel(tbl)
        newChoices = matlab.graphics.chart.internal.tableVariablesForTabCompletion(...
            tbl(i).SourceTable, args{:});
        choices = intersect(choices, newChoices);
    end
end

end

