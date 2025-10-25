function newname = checkRenamedToolboxFolders(oldname)
% CHECKRENAMEDTOOLBOXFOLDERS return the current name of a toolbox folder
%    NEWNAME=CHECKRENAMEDTOOLBOXFOLDERS(OLDNAME) returns the new name for a
%    toolbox folder if it has been renamed. If the toolbox does not exist
%    or has  not been renamed then the input name is returned unmodified.
%
%    Examples:
%
%    >> checkRenamedToolboxFolders('distcomp')
%    ans = 'parallel'
%
%    >> checkRenamedToolboxFolders('matlab')
%    ans = 'matlab'
%
%    See also VER, TOOLBOXDIR.

%    Copyright 2019 The MathWorks, Inc.

newname = oldname;

% Use a series of "if" statements as this is (marginally) faster than a
% switchyard or vectorized lookup.
checkname = deblank(newname);
if strcmpi(checkname,'fixpoint') % Renamed to "fixedpoint" in R2013a
    newname = 'fixedpoint';
elseif strcmpi(checkname,'xpc') % Renamed to "slrt" in R2014a
    newname = 'slrealtime';
elseif strcmpi(checkname,'slrt') % Renamed to "slreatime" in R2020b
    newname = 'slrealtime';
elseif strcmpi(checkname,'powersys') % Renamed to "sps" in R2018b
    newname = 'sps';
elseif strcmpi(checkname,'distcomp') % Renamed to "parallel" in R2019b
    newname = 'parallel';
elseif strcmpi(checkname,'simevents') % Renamed to "slde" in R2021b
    newname = 'slde';
elseif strcmpi(checkname,'compilersdk') % Renamed to "compiler_sdk" in R2024b
    newname = 'compiler_sdk';      
end