function success = helpwin(topic, varargin)
%HELPWIN MATLAB file help displayed in a window
%   HELPWIN TOPIC displays the help text for the specified TOPIC inside a
%   window.  Links are created to functions referenced in the 'See Also'
%   line of the help text.
%
%   HELPWIN displays the default topic list in a window.
%
%   HELPWIN will be removed in a future release. Use DOC instead. 
%
%   See also HELP, DOC.

%   Copyright 1984-2021 The MathWorks, Inc.

if nargout
    success = true;
end

if (nargin == 0)
    doc;
    return;
end

retCode = matlab.internal.help.helpwin.helpwin(topic, varargin{:});
if nargout
    success = retCode;
end

end