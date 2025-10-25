function [mfile,fcnname] = getWorkspace(offset)

% Utility method for brushing/linked plots. May change in a future release.

% Copyright 2008-2024 The MathWorks, Inc.

matlabToolboxPath = toolboxdir('matlab');
[dbstruct,dbI] = dbstack('-completenames');
if nargin==0
    stackPos  = -1;
    for k=1:numel(dbstruct)
        % Go up the stack to find the first non-matlab product file. This
        % is the location of the user file being debugged (g3434214)
        if ~startsWith(dbstruct(k).file,matlabToolboxPath)
            stackPos = k;
            break;
        end
    end
    if stackPos<1
        mfile = '';
        fcnname = '';
        return
    else
        mfile = dbstruct(stackPos).file;
        fcnname = dbstruct(stackPos).name;
    end
else
    % This is used for tests which specify a stack depth
    if length(dbstruct)>=(dbI+1+offset)
        mfile = dbstruct(dbI+1+offset).file;
        fcnname = dbstruct(dbI+1+offset).name;
    else
        mfile = '';
        fcnname = '';
        return
    end

    % Be sure that mfile is not part of matlab/toolbox, which means that
    % a drawnow has triggered the calling function from an unexpected
    % workspace.
    k = dbI+2+offset;
    while ~contains(lower(mfile),matlabToolboxPath)
        if k<=length(dbstruct)
            mfile = dbstruct(k).file;
            fcnname = dbstruct(k).name;
        else
            mfile = '';
            fcnname = '';
            return
        end
        k = k+1;
    end
end