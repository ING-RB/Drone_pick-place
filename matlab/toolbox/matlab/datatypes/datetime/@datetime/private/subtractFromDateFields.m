function bdata = subtractFromDateFields(adata,amounts,fieldIDs,timeZone)
%SUBTRACTFROMDATEFIELDS Subtract specified amounts from specified fields of a datetime, for zoned and unzoned cases.
%   BDATA = SUBTRACTFROMDATEFIELDS(ADATA,AMOUNTS,FIELDIDS,TIMEZONE)
%   subtracts the field amounts in AMOUNTS from the datetime doubledouble
%   data ADATA. AMOUNTS is a cell array of numeric values and FIELDIDS is a
%   numeric array of corresponding field IDs from datetime.dateFields
%   indicating the units of each value in AMOUNTS. TIMEZONE is the time
%   zone to be used in the calculation and can be an empty char to indicate
%   unzoned.
%
%   Examples
%
%      % Subtract 13 months, 1 day of the month, and 1 millisecond of a day
%      % from the doubledouble data of a datetime 'x' in x's timezone.
%      x.data = subtractFromDateFields(x.data,{13,1,1},[datetime.dateFields.MONTH datetime.dateFields.DAY_OF_MONTH datetime.dateFields.MILLISECOND_OF_DAY],x.tz);

%   Copyright 2014-2020 The MathWorks, Inc.

bdata = adata;
for field = 1:length(amounts)
    amount = amounts{field};
    if ~isequal(amount,0)
        bdata = matlab.internal.datetime.addToDateField(bdata,-amount,fieldIDs(field),timeZone);
    end
end
