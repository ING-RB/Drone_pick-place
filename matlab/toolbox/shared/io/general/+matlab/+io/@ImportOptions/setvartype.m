function opts = setvartype(opts,varargin)

import matlab.io.internal.validators.validateCellStringInput;

narginchk(2,3);
if nargout == 0
    error(message('MATLAB:textio:io:NOLHS','setvartype','setvartype'))
end

v_opts = opts.fast_var_opts;
if nargin == 2
    % setvartype(OPTS,TYPE) syntax
    selection = 1:v_opts.numVars;
    type = varargin{1};
elseif isnumeric(varargin{1})
    selection = varargin{1};
    type = varargin{2};
elseif islogical(varargin{1})
    selection = find(varargin{1});
    type = varargin{2};
else
    selection = validateCellStringInput(convertStringsToChars(varargin{1}), 'SELECTION');
    if iscell(selection) || ischar(selection)
        % Get the appropriate numeric indices and error for unknown variable names.
        selection = opts.getNumericSelection(selection);
    end
    type = convertStringsToChars(varargin{2});
end

% Convert to cellstr
try type = convert2cellstr(type); catch
    error(message('MATLAB:textio:textio:InvalidStringOrCellStringProperty','TYPES'));
end

% Expand scalar
if isscalar(type)
    type = repmat(type,size(selection));
elseif numel(type) ~= numel(selection)
    error(message('MATLAB:textio:io:MismatchVarTypes'))
end

% Set the underlying types
try
    opts.fast_var_opts = v_opts.setTypes(selection, type);
catch ME
    throw(ME)
end
end

% Copyright 2016-2023 The MathWorks, Inc.