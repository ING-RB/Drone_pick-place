function validateTabularShape(T)
%VALIDATETABULARSHAPE Validates T is tabular and has at least one variable. 
% 
% Does not validate the variables of T can be written to Parquet. See
% matlab.io.arrow.matlab2arrow for details about datatypes that are supported
% for writing to Parquet. 

% Copyright 2022 The MathWorks, Inc.

    if ~(istable(T) || istimetable(T))
        error(message("MATLAB:parquetio:table:DataNotTabular"));
    end

    if width(T) == 0
        error(message("MATLAB:parquetio:write:InvalidZeroVars"));
    end
end

