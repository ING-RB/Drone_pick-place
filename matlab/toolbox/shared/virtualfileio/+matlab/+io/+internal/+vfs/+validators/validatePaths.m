function pths = validatePaths(pths)
%VALIDATEPATHS Validates the input paths.

%   Copyright 2015-2018 The MathWorks, Inc.

    import matlab.io.datastore.internal.validators.trailingPeriodsAndWhitespaces
    % empty cell array {} is a valid input
    if iscell(pths) && isempty(pths)
        return;
    end

    pcResult = ispc;
    if ~(isstring(pths) || (ischar(pths) && ( isrow(pths) || isequal(pths, '') )) || iscellstr(pths))
        error(message('MATLAB:virtualfileio:path:invalidStrOrCellStr','Files'));
    elseif iscell(pths)
        for i = 1:numel(pths)
            if ~(ischar(pths{i}) && (isrow(pths{i}) || strcmp(pths{i},'')))
                error(message('MATLAB:virtualfileio:path:invalidStrOrCellStr','Files'));                                                        
            elseif pcResult
                % if path contains trailing periods or whitespaces, error
                trailingPeriodsAndWhitespaces(pths{i});
            end
        end
    elseif ischar(pths) && pcResult
        % if path contains trailing periods or whitespaces, error
        trailingPeriodsAndWhitespaces(pths);
    end

    pths = cellstr(pths);    
    % inputs cannot contains empty elements
    if (any(cellfun('isempty', pths)))
        error(message('MATLAB:virtualfileio:path:cellWithEmptyStr','Files'));
    end
end
