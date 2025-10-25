function bdata = addToDateFields(adata,amounts,fieldIDs,timeZone)
%ADDTODATEFIELDS Add specified amounts to specified fields of a datetime, for zoned and unzoned cases.
%   BDATA = ADDTODATEFIELDS(ADATA,AMOUNTS,FIELDIDS,TIMEZONE) adds datetime
%   doubledouble data ADATA to the field amounts in AMOUNTS. AMOUNTS is a
%   cell array of numeric values and FIELDIDS is a numeric array of
%   corresponding field IDs from datetime.dateFields indicating the units
%   of each value in AMOUNTS. TIMEZONE is the time zone to be used in the
%   calculation and can be an empty char to indicate unzoned.
%
%   Examples
%
%      % Add 13 months, 1 day of the month, and 1 millisecond of a day to
%      % the doubledouble data of a datetime 'x' in x's timezone.
%      x.data = addToDateFields(x.data,{13,1,1},[datetime.dateFields.MONTH datetime.dateFields.DAY_OF_MONTH datetime.dateFields.MILLISECOND_OF_DAY],x.tz);

%   Copyright 2014-2020 The MathWorks, Inc.

bdata = adata;
for field = 1:length(amounts)
    amount = amounts{field};
    if ~isequal(amount,0)
        bdata = matlab.internal.datetime.addToDateField(bdata,amount,fieldIDs(field),timeZone);
    end
end
