% Returns the size of the variable. Handles objects which may have a scalar size
% (like Java collection objects), or objects which may not have a numeric size.

% Copyright 2015-2023 The MathWorks, Inc.

function varSize = getVariableSize(value, varargin)
    try
        if isa(value, 'tall')
            w = whos('value');
            varSize = w.size;
        else
            try
                varSize = size(value);
            catch
                % Assume a size of 1x1 for objects which error on size
                varSize = [1 1];
            end
            if isscalar(varSize)
                % Assume a size of 1,1
                varSize = [1 1];
            end
        end
    catch
        % Assume [1,1] if there's an error (which can happen when an object is
        % open in the editor, and an error is inserted)
        varSize = [1 1];
    end

    if nargin == 2
        dimension = varargin{1};
        varSize = varSize(dimension);
    end
end
