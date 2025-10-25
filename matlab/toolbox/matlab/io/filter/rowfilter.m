function filter = rowfilter(variableNames)
%ROWFILTER   Create an object for filtering rows in a table or timetable.
%
%   FILTER = rowfilter(VARNAMES) creates a matlab.io.RowFilter object that
%       operates on VARNAMES. For example:
%
%           f = rowfilter(["Region" "OutageTime" "Cause"]);
%
%       Use relational operators to express filtering constraints on these variables.
%
%           data = parquetread("outages.parquet", RowFilter = (f.Region == "SouthWest"));
%
%       The following relational operators are supported: <, <=, >, >=, ==, ~=
%
%   FILTER = rowfilter(INFO) creates a matlab.io.RowFilter object that
%       uses the variable names in an INFO object generated using parquetinfo:
%
%           info = parquetinfo("outages.parquet");
%           f = rowfilter(info);
%           data = parquetread("outages.parquet", RowFilter = f.Loss < 100);
%
%   FILTER = rowfilter(PDS) creates a matlab.io.RowFilter object that
%       uses the variable names in the ParquetDatastore PDS:
%
%           pds = parquetDatastore("outages.parquet");
%           f = rowfilter(pds);
%           pds.RowFilter = (f.Customers > 2e6);
%           data = pds.readall();
%
%   FILTER = rowfilter(T) creates a matlab.io.RowFilter object that
%       uses the variable names in the table or timetable T:
%
%           tt = readtimetable("outages.csv");
%           f = rowfilter(tt);
%           f = (f.Cause == "unknown");
%           data = tt(f,:);
%
%   To express multiple filtering constraints, combine rowfilter objects
%       using the &, |, or ~ operators:
%
%           f = (f.OutageTime >= "2006-01-01") & (f.OutageTime < "2006-02-01");
%
%           data = parquetread("outages.parquet", RowFilter=f);
%
%   See also: PARQUETREAD, PARQUETDATASTORE, PARQUETINFO, PARQUETWRITE, TABLE, TIMETABLE, EVENTFILTER.

% Copyright 2021-2023 The MathWorks, Inc.

    try
        filter = matlab.io.RowFilter(variableNames);
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
