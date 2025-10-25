function varname = cleanVarName(name)
% cleanVarName: Helper for performing tasks in a Live Script
% This function will prep an arbitrary variable name for input into a
% generated script
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2020 The MathWorks, Inc.

% first, replace any quotes in the name with two quotes,
% so they revert back to one on eval
name = strrep(name,'"','""');
hasNewlines = any(name == newline);

if ~hasNewlines
    % no newlines, add quotes around the name
    varname = ['"' name '"'];
else
    % there are new lines, replace them with the appropriate string 
	% addition to create newlines in a script
    varname = ['"' strrep(name,newline,'" + newline + "') '"'];
end

end