function outVector = ArrayEditorReset(thisTs,row,col)
%

% Copyright 2006-2017 The MathWorks, Inc.

% Timeseries has been changed. This static method is called from java
% after a variable update for a combined re-computation of the
% cache and return of the key object parameters. These operations
% are combined to minimize MATLAB<->java traffic

import java.util.*;

if ~isequal(size(thisTs),[1 1])
    outVector = regexprep(evalc("builtin('disp',thisTs)"),"<.*?>","") ;
    return;   
end

row = max(row,0);
col = max(col,0);
newCache = tsguis.UpdateArrayEditorTableCache(thisTs,row,col);

% For 3d or invalid timeseries, just return a string representation for
% display only
if isempty(newCache)
    outVector = regexprep(evalc("utDisplay(thisTs)"),"<.*?>","");
    return;
end

% For valid 2d timeseries, return a Vector with events, times and cache
[nameVal,eventVector,currentTimeStr] = tsguis.ArrayEditorGetAll(thisTs);
outVector = Vector;
outVector.addElement(java.lang.String(nameVal));
outVector.addElement(eventVector);
outVector.addElement(currentTimeStr);
outVector.addElement(newCache);