function varargout = recursiveGather(varargin)
%RECURSIVEGATHER Recursively gathers the inputs
%   [Y1,Y2,Y3,...] = matlab.internal.parallel.recursiveGather(X1,X2,X3,...) 
%   recursively gathers the inputs X1 X2, X3,... and returns the gathered
%   objects as Y1, Y2,... 
%   For cell inputs, each cell element will be gathered recursively.
%   For struct inputs, each struct field will be gathered recursively.
%   For tabular inputs, each variable will be gathered recursively.

% Copyright 2024 The MathWorks, Inc.

if nargout > nargin
    error(message("MATLAB:nargoutchk:tooManyOutputs"));
end

% First call the standard gather on all inputs.  This ensures that remote
% cells, structs and tables (as opposed to cells, structs or tables
% containing remote data) are gathered appropriately.
varargout = varargin;
[varargout{:}] = gather(varargout{:});

% Check which things need recursion
needsRecurse = matlab.bigdata.internal.needsRecursiveGather(varargout{:});

% Then recurse though any cells, structs or tabular objects
if any(needsRecurse)
    idx = find(needsRecurse);
    for ii=idx
        varargout{ii} = iRecursiveGatherOne(varargout{ii});
    end
end
end



function x = iRecursiveGatherOne(x)
% Deal with one input, maybe recursing if it is a container.

if iscell(x)
    [x{:}] = matlab.internal.parallel.recursiveGather(x{:});

elseif isstruct(x)
    % Struct array. Need to gather all fields of all structs.
    y = struct2cell(x);
    [y{:}] = matlab.internal.parallel.recursiveGather(y{:});
    x = cell2struct(y,fieldnames(x));

else % if istabular(x) - should always be tabular if not cell or struct
    % Extract variables into a cell array. Weirdly a for-loop is faster
    % than varfun here.
    w = width(x);
    c = cell(1,w);
    for ii = 1:w
        c{ii} = x.(ii);
    end
    [c{:}] = matlab.internal.parallel.recursiveGather(c{:});
    for ii = 1:w
        x.(ii) = c{ii};
    end
end

end