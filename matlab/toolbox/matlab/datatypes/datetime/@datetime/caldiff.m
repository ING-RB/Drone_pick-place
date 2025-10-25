function d = caldiff(a,components,dim)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.diffDateFields
import matlab.internal.datetime.checkCalendarComponents
import matlab.internal.datatypes.isScalarInt

if nargin > 1
    components = convertStringsToChars(components);
end

narginchk(1,3);

data = a.data;
if nargin < 3
    dim = find(size(data)~=1,1);
    if isempty(dim), dim = 1; end
else
    if ~isScalarInt(dim,1)
        error(message('MATLAB:datetime:InvalidDim'));
    end
end
[aData,bData] = lagData(data,dim);
ucal = datetime.dateFields;
fieldIDs = [ucal.EXTENDED_YEAR ucal.QUARTER ucal.MONTH ucal.WEEK_OF_YEAR ucal.DAY_OF_MONTH ucal.MILLISECOND_OF_DAY];
if (nargin == 1) || isempty(components)
    fields = [1 3 5 6];
    [cdiffs{1:4}] = diffDateFields(aData,bData,fieldIDs(fields),a.tz);
    d = calendarDuration(cdiffs{:});
else
    if isa(components,"datetime")
        ME = MException(message('MATLAB:datetime:BetweenNotCaldiff'));
        correction = matlab.lang.correction.ReplaceIdentifierCorrection('caldiff', 'between');
        throw(addCorrection(ME,correction));
    end
    fields = checkCalendarComponents(components);
    cdiffs = {0 0 0 0 0 0};
    [cdiffs{fields}] = diffDateFields(aData,bData,fieldIDs(fields),a.tz);
    cdiffs{3} = cdiffs{3} + 3*cdiffs{2}; % add quarters into months
    cdiffs{5} = cdiffs{5} + 7*cdiffs{4}; % add weeks into days
    fmt = 'yqmwdt'; fmt = fmt(union(fields,[3 5 6])); % always include mdt
    d = calendarDuration(cdiffs{[1 3 5 6]},'Format',fmt);
end


%-------------------------------------------------------------------------------
function [aData,bData] = lagData(data,dim)
if ismatrix(data)
    if dim == 1
        aData = data(1:end-1,:);
        bData = data(2:end,:);
    elseif dim == 2
        aData = data(:,1:end-1);
        bData = data(:,2:end);
    else
        aData = zeros([size(data) 0]);
        bData = zeros([size(data) 0]);
    end
else
    szOut = size(data);
    if dim > length(szOut), szOut(end+1:dim) = 1; end
    szOut(dim) = max([0;szOut(dim) - 1]);
    
    subs = repmat({':'},1,length(szOut));
    subs{dim} = 1:szOut(dim);
    aData = reshape(data(subs{:}),szOut);
    subs{dim} = subs{dim} + 1;
    bData = reshape(data(subs{:}),szOut);
end
