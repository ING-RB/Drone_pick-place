% Returns the start column indices of a table, timetable, or dataset, which
% takes into account any grouped columns.  For example, a 4 variable table with
% no grouped columns returns: [1,2,3,4,5], while if it has its middle two
% columns grouped, it returns: [1,2,4,5]

% Copyright 2020-2022 The MathWorks, Inc.

function startColumnIndexes = getColumnStartIndicies(data)
    arguments
        data {mustBeA(data, ["table", "timetable", "dataset"])}
    end

    if isa(data, "dataset")
        startColumnIndexes = cumsum([1, datasetfun(@(x) max(size(x,2)*ismatrix(x)*~ischar(x)*~isa(x,"dataset")*~istabular(x) + ischar(x) + isa(x,"dataset") + istabular(x), 1), data, "UniformOutput", true)]);
    else
        startColumnIndexes = cumsum([1, varfun(@(x) max(size(x,2)*ismatrix(x)*~ischar(x)*~isa(x,"dataset")*~istabular(x) + ischar(x) + isa(x,"dataset") + istabular(x), 1), data, "OutputFormat", "uniform")]);
    end
end
