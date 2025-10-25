function iseq = isequalwithequalnans(ts1,ts2)
%

% Copyright 2007-2024 The MathWorks, Inc.

narginchk(2,2);

iseq = false;
if ~isequal(size(ts1),size(ts2))  
    return
end

% Make sure we have two timeseries
if ~isa(ts1, 'timeseries') || ~isa(ts2, 'timeseries')    
    return;
end

if isempty(ts1) && isempty(ts2)
    iseq = true;
    return
end
for k=1:numel(ts1)
    iseq = isequalwithequalnans(ts1(k).Data,ts2(k).Data) && ...
        isequal(ts1(k).Time,ts2(k).Time) && ...
        isequal(ts1(k).Quality,ts2(k).Quality) && ...
        isequal(ts1(k).DataInfo,ts2(k).DataInfo) && ...
        isequal(ts1(k).TimeInfo,ts2(k).TimeInfo) && ...
        isequal(ts1(k).QualityInfo,ts2(k).QualityInfo) && ...
        isequal(ts1(k).Name,ts2(k).Name) && ...
        isequal(ts1(k).TreatNaNasMissing,ts2(k).TreatNaNasMissing) && ...
        isequal(ts1(k).IsTimeFirst,ts2(k).IsTimeFirst) && ...
        isequal(ts1(k).Events,ts2(k).Events);
    if ~iseq
        return
    end
end