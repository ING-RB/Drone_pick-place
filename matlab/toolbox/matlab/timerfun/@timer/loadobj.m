function obj = loadobj(B)
%LOADOBJ Load filter for timer objects.
%
%   OBJ = LOADOBJ(B) is called by LOAD when a timer object is
%   loaded from a .MAT file. The return value, OBJ, is subsequently
%   used by LOAD to populate the workspace.
%
%   LOADOBJ will be separately invoked for each object in the .MAT file.
%

%    Copyright 2001-2019 The MathWorks, Inc.

%The check for a struct is to support old style Timers. (Version 1)
% NOTE: LOADOBJ gets called for all mat files being loaded pre-R2008a
% loadObjectArray gets called for all mat files loaded from R2008a and
% beyond
if isfield(B, 'jobject')
    % note: we are throwing error, but the mcos loadobj callsite turns all
    % errors into warnings. And save the returning obj as a struct :(
    obj = setinvalidTimerBasedOnLoadingSize(B);
    
    warning(message('MATLAB:timer:incompatibleTimerLoad'));
    % do not delete the return, mcos loadobj has its warning handling, and will act like a
    % fallthrough in some cases
    return;
end

if isstruct(B)
    obj = timer(B);
else
    % we give up case
    obj = B;
    warning(message('MATLAB:timer:unableToLoad'));
end
end