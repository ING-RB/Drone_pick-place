function s = setfield(s,varargin)
 
%   Copyright 1984-2023 The MathWorks, Inc.

% Check for sufficient inputs
if (isempty(varargin) || length(varargin) < 2)
    error(message('MATLAB:setfield:InsufficientInputs'));
end

% The most common case
arglen = length(varargin);
strField = varargin{1};
if (arglen==2)
    s.(deblank(strField)) = varargin{end};    
    return
end
        
subs = varargin(1:end-1);
types = cell(1, arglen-1);
for i = 1:arglen-1
    index = varargin{i};
    if (isa(index, 'cell'))
        types{i} = '()';
    elseif ischar(index) || isstring(index)    
        types{i} = '.';
        subs{i} = deblank(index); % deblank field name
    else
        error(message('MATLAB:setfield:InvalidType'));
    end
end

% Perform assignment
try 
    % don't use substruct, because there may be multiple levels in type and subs
    s = builtin('subsasgn', s, struct('type',types,'subs',subs), varargin{end});   
catch exception
    exceptionToThrow = MException('MATLAB:setfield', '%s', exception.message);
    throw(exceptionToThrow);
end






