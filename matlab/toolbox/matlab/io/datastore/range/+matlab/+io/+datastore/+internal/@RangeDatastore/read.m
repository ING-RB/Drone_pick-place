function [data, info] = read(rds)
%READ   Return the next value from the RangeDatastore.
%
%   DATA = READ(RDS) reads the next value from the RangeDatastore.
%
%       DATA will have one row, unless "ReadSize" has been set to a value greater than 1.
%
%   [DATA, INFO] = READ(RDS) also returns a struct containing additional information
%   about DATA. The fields of INFO are:
%       - ValueIndex - Indices of the values read, relative to the Start property.
%
%   See also: matlab.io.datastore.internal.RangeDatastore

%   Copyright 2021 The MathWorks, Inc.

    if ~rds.hasdata()
        msgid = "MATLAB:io:datastore:common:read:NoMoreData";
        error(message(msgid));
    end

    % Compute start and end indices based on NumValuesRead.
    StartIndex = rds.Start + rds.NumValuesRead;
    EndIndex = StartIndex + rds.ReadSize - 1;

    % Account for the possibility that the last read has fewer than ReadSize values.
    if EndIndex > rds.End
        EndIndex = rds.End;
    end

    % Return the actual indices corresponding to this range.
    data = StartIndex:EndIndex;
    data = reshape(data, [], 1);

    % Get the info struct values by just shifting the data values.
    ValueIndices = num2cell(data - rds.Start + 1);
    info = struct("ValueIndex", ValueIndices);

    % Increment the iterator after reading is completed.
    rds.NumValuesRead = rds.NumValuesRead + numel(data);
end
