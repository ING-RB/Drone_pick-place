function warning( warnId, varargin )
% DASTUDIO.WARNING(warnId, varargin ) go from warnId to warn message then call warning
%   Will translate a messageId into a string and pass both of them to
%   the MATLAB warning function.  It will also update sllastwarning if requested
%   by the component.
%
%   To use this function for an already created message id
%   call DAStudio.warning( warnId, args)
%
%   Valid syntax for warnId in DAStudio.warning is
%
%   product:component:messageId
%
%   The variable arguments args are used to fill in the predefined 
%   holes in the message string.

% This function is used to report a warning from MATLAB-code with the following 
% advantages over the MATLAB warning function
%
% 1) Force the use of messageID's for 
%       a) better testing
%       b) localization capability
%
% 2) This also puts all warnings through a common funnel for future upgrades
% 
%   Copyright 1990-2010 The MathWorks, Inc.

if nargin > 0
    warnId = convertStringsToChars(warnId);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

diag_obj = MSLDiagnostic(message(warnId, varargin{:}));
diag_obj.reportAsWarning;
