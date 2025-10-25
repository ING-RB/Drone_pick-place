%mlreportgen.utils.safeGet calls GET, but never errors and always returns a vertical cell array
%
%   SAFEGET(HANDLE,PROPNAME)
%     PROPNAME must be a single string
%     HANDLE can be a scalar or vector double, scalar or vector handle
%
%   SAFEGET(HANDLE,PROPNAME,'get_param') will work for Simulink.  HANDLE
%     can be a string name, cell array of names, or scalar/vector double handle
%   SAFEGET(HANDLE,PROPNAME,'sf','get') will work for Stateflow.
%
%   SAFEGET always returns a cell array column vector of results.  If
%     there was an error getting the result, the cell entry is 'N/A'
%   [VALUES,BADIDX]=SAFEGET(...) will return indices of error N/A entries.

 
%   Copyright 2021 The MathWorks, Inc.

