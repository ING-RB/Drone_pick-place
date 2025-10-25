function d = between(a,b,components)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.diffDateFields
import matlab.internal.datetime.checkCalendarComponents

narginchk(2,3);

[a,b] = datetime.arithUtil(a,b);
if ~isa(a,'datetime') || ~isa(b,'datetime')
    error(message('MATLAB:datetime:InvalidComparison',class(a),class(b)));
end

aData = a.data;
bData = b.data;
ucal = datetime.dateFields;
fieldIDs = [ucal.EXTENDED_YEAR ucal.QUARTER ucal.MONTH ucal.WEEK_OF_YEAR ucal.DAY_OF_MONTH ucal.MILLISECOND_OF_DAY];
if nargin < 3
    fields = [1 3 5 6];
    [cdiffs{1:4}] = diffDateFields(aData,bData,fieldIDs(fields),a.tz);
    d = calendarDuration(cdiffs{1:4});
else
    fields = checkCalendarComponents(components);
    cdiffs = {0 0 0 0 0 0};
    [cdiffs{fields}] = diffDateFields(aData,bData,fieldIDs(fields),a.tz);
    cdiffs{3} = cdiffs{3} + 3*cdiffs{2}; % add quarters into months
    cdiffs{5} = cdiffs{5} + 7*cdiffs{4}; % add weeks into days
    fmt = 'yqmwdt'; fmt = fmt(union(fields,[3 5 6])); % always include mdt
    d = calendarDuration(cdiffs{[1 3 5 6]},'Format',fmt);
end
