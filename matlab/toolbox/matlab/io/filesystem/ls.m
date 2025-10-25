function varargout = ls(varargin)

if nargout > 1
    error(message('MATLAB:ls:TooManyOutputArguments'));
end

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
    if ~iscellstr(varargin)
        error(message('MATLAB:ls:InputsMustBeStrings'));
    end

    try
        isURL = any(matlab.io.internal.vfs.validators.isIRI(varargin));
    catch
        isURL = false;
    end

    if isURL
        error(message('MATLAB:ls:URLNotAllowed'));
    end
end

% perform platform specific directory listing
try
    nOut = nargout;
    if isunix
        [varargout{1:nOut}] = unixImpl(nOut, varargin{:});
    else
        [varargout{1:nOut}] = winImpl(nOut,varargin{:});
    end
catch ME
    throw(ME);
end
end

% Copyright 1984-2024 The MathWorks, Inc.

% ======================================================
function varargout = unixImpl(nOut,varargin)
import matlab.oss.internal.quoteUnixCmdArg;
pd = pwd;


args = quoteUnixCmdArg(varargin{:});


if isfolder(pd)
    % if pwd has a    $, `, \ ,
    % in unix shell those characters can get expanded (if contained by double qoutes)
    % and have unusual effects. So they must be escaped in that case.
    thePatternToEscpae = characterListPattern("$\`");
    pd = insertBefore(pd, thePatternToEscpae, "\"); %handle pathname with either of '$ \ `
    cmd = ['cd "' pd '" < /dev/null && ls' args];
else
    cmd = ['ls' args];
end
[s,listing] = matlab.system.internal.executeCommand(cmd);

if s ~= 0
    error(message('MATLAB:ls:OSError',listing));
end

if nOut == 0
    disp(listing);
else
    varargout{1} = listing;
end

end

% ======================================================
function listing = winImpl(nOut,varargin)
if numel(varargin) > 1
    error(message('MATLAB:ls:TooManyInputArguments'));
end
% Display output of dir in wide format.
% dir; prints out info.
% d = dir; does not.
if nOut == 0
    dir(varargin{:});
else
    d = dir(varargin{:});
    listing = char(d.name);
end
end
