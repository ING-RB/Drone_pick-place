function  error( msgID, varargin )
%This class is for internal use only. It may be removed in the future.

%ERROR Internal error message function with codegen compatibility. Supports
%   up to one custom argument holes (as defined in the message catalog).
%   varargin is one char array. Additional conditionals may be added as
%   needed, in which case varargin will handle multiple char arrays.
%   NOTES this method is NOT for top-level function codegen.

%#codegen
    
%   Copyright 2023-2024 The MathWorks, Inc.

rb = 'shared_robotics';
component = 'robotcore';
narginchk(1,4);
if nargin == 1
    if coder.target('MATLAB')
        error(message([rb ':' component ':' msgID]));
    else
        coder.internal.error([rb ':' component ':' msgID]);
    end
elseif nargin == 2
    if coder.target('MATLAB')
        error(message([rb ':' component ':' msgID], varargin{1}));
    else
        mid = coder.const(msgID);
        coder.internal.error([rb ':' component ':' mid], varargin{1});
    end
end
    
    
end

