function clearBreakpoint(filename, requestedBreakpoint)
%   clearBreakpoint clears a breakpoint in the given file
%
%   This function is unsupported and might change or be removed without
%   notice in a future version. 

%   This function tries to clear a breakpoint in MATLAB from the
%   information provided in the given Java breakpoint. 
%
%   clearbreakpoint(filename, requestedBreakpoint)
%     filename  is the MATLAB char array containing the file name to set the breakpoint in.
%     requestedBreakpoint the com.mathworks.mde.editor.breakpoints.MatlabBreakpoint
%                         from which to derive the inputs for the call to
%                         dbclear.

%   Copyright 2012-2018 The MathWorks, Inc.

    try
        doSetBreakpoint(filename, requestedBreakpoint, true);
    catch exception
        if strcmp(exception.identifier,'MATLAB:lineBeyondPFileEnd') == 0 || ...
            strcmp(exception.identifier,'MATLAB:lineBeyondFileEnd') == 0
            % In the case that the pfile is out of sync with an mfile, try
            % to clear the breakpoint from the mfile
            clearBreakpointFromCorrespondingMFile(filename, requestedBreakpoint);
            return;
        end
        
        throw(exception);
    end
end

function clearBreakpointFromCorrespondingMFile(pFilename, requestedBreakpoint)
    [filepath, filename] = fileparts(pFilename);
    mfile = fullfile(filepath, [filename '.m']);
    doSetBreakpoint(mfile, requestedBreakpoint, true);
end
