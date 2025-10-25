function varsOrTypes = validateVarsTypes(varsOrTypes, propName, onConstruction, usingDefaults)
%VALIDATEVARSTYPES Validates variable names and types
%   This is a helper function that validates the VariableNames,
%   SelectedVariableNames, TextscanFormats, SelectedFormats, VariableTypes,
%   SelectedVariableTypes.

%   Copyright 2015-2018 The MathWorks, Inc.

    % imports
    import matlab.io.internal.validators.isCharVector;
    import matlab.io.internal.validators.isCellOfCharVectors;
    
    % validate arguments
    if nargin < 3
        onConstruction = false;
        usingDefaults = {};
    end
    
    if nargin < 4
        usingDefaults = {};
    end
    
    % error for cases when {} is explicitly passed during construction
    if onConstruction
        isDefault = isequal(varsOrTypes, {});
        if isDefault
            if ~ismember(propName, usingDefaults)
                error(message('MATLAB:datastoreio:tabulartextdatastore:invalidStrOrCellStr', propName));
            end
            return;
        end
    end
    
    % '', {}, [] must error, {} passed during construction already handled
    % above
    if isempty(varsOrTypes)
        error(message('MATLAB:datastoreio:tabulartextdatastore:emptyVar', propName));
    end

    try
    	% make inputs cell arrays of strings, cellstr works on chars, cellstrs.
        matlab.io.internal.validators.validateCellStringInput(varsOrTypes, propName, true);
    	varsOrTypes = cellstr(varsOrTypes);
    catch
	    % inputs must be strings or cell array of strings
    	if ~isCharVector(varsOrTypes) || ~isCellOfCharVectors(varsOrTypes) || ~isstring(pths)
        	error(message('MATLAB:datastoreio:tabulartextdatastore:invalidStrOrCellStr', propName));
    	end
    end
    
    
    % convert column vectors to row vectors
    varsOrTypes = varsOrTypes(:)';

    % inputs cannot contains empty elements
    if (any(cellfun('isempty', varsOrTypes)))
        error(message('MATLAB:datastoreio:tabulartextdatastore:cellWithEmptyStr', propName));
    end
end
