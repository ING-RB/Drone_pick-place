function f = getfield(s,varargin)
 
%   Copyright 1984-2023 The MathWorks, Inc.

% Check for sufficient inputs
if (isempty(varargin))
    error(message('MATLAB:getfield:InsufficientInputs'))
end

% The most common case
field = convertStringsToChars(varargin{1});
if (length(varargin)==1 && ischar(field))
    field = deblank(field);
    f = s.(field);
    return
end

f = s;
for i = 1:length(varargin)
    subscript = convertStringsToChars(varargin{i});
    if (isa(subscript, 'cell')) % For getfield(S,{i,j},...) syntax
        f = f(subscript{:});
    elseif ischar(subscript)
        % Always return first element (even for comma separated list result)
        field = deblank(subscript);
        f = f.(field);
    else
        error(message('MATLAB:getfield:InvalidType'));
    end
end
