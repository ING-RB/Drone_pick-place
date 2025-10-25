function t = tsgetrelativetime(date,dateRef,unit)
% 

% this method calculates relative time value between date absolute dateref.

%  Copyright 2004-2016 The MathWorks, Inc.

if iscellstr(dateRef)
    vecRef = datevec(dateRef); 
elseif iscell(dateRef) || isstring(dateRef)
    vecRef = datevec(cellstr(dateRef));
elseif ischar(dateRef)
    vecRef = datevec(char(dateRef));
else
    vecRef = datevec(dateRef);
end
if iscellstr(date)
    vecDate = datevec(date);
elseif iscell(date) || isstring(date)
    vecDate = datevec(cellstr(date));
elseif ischar(date)
    vecDate = datevec(char(date));
else
    vecDate = datevec(date);
end
t = tsunitconv(unit,'days')*(datenum([vecDate(:,1:3) zeros(size(vecDate,1),3)])-datenum([vecRef(1:3) 0 0 0])) + ...
    tsunitconv(unit,'seconds')*(vecDate(:,4:6)*[3600 60 1]'-vecRef(:,4:6)*[3600 60 1]');
