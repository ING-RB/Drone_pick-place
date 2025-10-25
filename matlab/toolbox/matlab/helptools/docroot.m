function helpDir = docroot(new_docroot)
%DOCROOT A utility to get or set the root directory of MATLAB Help
%   DOCROOT returns the current docroot.
%   DOCROOT(NEW_DOCROOT) sets the docroot to the new docroot, whether or
%   not the new docroot is a valid directory.  A warning is printed out if
%   the directory appears to be invalid.
%
%   The documentation root directory is set by default to be
%   MATLABROOT/help.  This value should not need to be changed, since
%   documentation in other locations may not be compatible with the running
%   version. However, if documentation from another location is desired,
%   docroot can be changed by calling this function to set the value to
%   another directory. This value is not saved in between sessions.  To set
%   this value every time MATLAB is run, a call to docroot can be inserted
%   into startup.m.

%   Copyright 1984-2022 The MathWorks, Inc.

% If at least one argument is passed in, set the user docroot. Otherwise,
% get the docroot.
if nargin > 0
    charIn = ischar(new_docroot);
    if charIn
        new_docroot = string(new_docroot);
    end

    helpDir = matlab.internal.doc.services.setDocroot(new_docroot);

    if charIn
        helpDir = char(helpDir);
    end    
else
    helpDir = char(matlab.internal.doc.docroot.getDocroot);
end