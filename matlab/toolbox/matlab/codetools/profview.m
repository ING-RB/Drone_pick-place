function htmlOut = profview(varargin)
%PROFVIEW   Display HTML profiler interface
%   This function is unsupported and might change or be removed without
%   notice in a future version.
%
%   PROFVIEW(FUNCTIONNAME, PROFILEINFO)
%   FUNCTIONNAME can be either a name or an index number into the profile.
%   PROFILEINFO is the profile stats structure as returned by
%   PROFILEINFO = PROFILE('INFO').
%   If the FUNCTIONNAME argument passed in is zero, then profview displays
%   the profile summary page.
%
%
%   See also PROFILE.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability;
Capability.require(Capability.LocalClient);

matlab.internal.profileviewer.updateProfileViewer(matlab.internal.profileviewer.ProfilerType.MATLAB, @profile, varargin{:});

if nargout == 1
    htmlOut = '';
end
