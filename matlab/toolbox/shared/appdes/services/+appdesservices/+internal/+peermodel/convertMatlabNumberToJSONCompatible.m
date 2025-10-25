function jsonCompatibleValue = convertMatlabNumberToJSONCompatible(matlabValue)
% CONVERTMATLABNUMBERTOJSONCOMPATIBLE 
% Converts a MATLAB double array with Inf/-Inf/NaN to JSON compatible

% Copyright 2016 - 2017 The MathWorks, Inc.

    % Default output will keep unchanged
    jsonCompatibleValue = matlabValue;
    
    if isnumeric(matlabValue) && (any(isinf(matlabValue), 'all') || any(isnan(matlabValue), 'all'))
        % JSON does not handle Inf/-Inf and NaN
        if(isscalar(matlabValue))
            % convert Inf / -Inf to 'Inf' / '-Inf', and Nan to 'NaN'
            jsonCompatibleValue = num2str(matlabValue);
        else
            % convert [0 Inf] / [0 -Inf] to {0 'Inf] / {0 '-Inf'}
            % conver [0 NaN[ to {0 'NaN'}
            if iscell(matlabValue)
                jsonCompatibleValue = cellfun(@(x) (convertElement(x)), matlabValue, 'UniformOutput', false);
            else
                % if matlabValue is a numeric array, converting just the
                % minimal values is faster than using cellfun on all
                % elements
                shouldConvert = ~isfinite(matlabValue);
                jsonCompatibleValue = num2cell(matlabValue);
                indicies = find(shouldConvert);
                for idx = 1:numel(indicies)
                    matlabValueIndex = indicies(idx);
                    jsonCompatibleValue{matlabValueIndex} = num2str(matlabValue(matlabValueIndex));
                end
            end
            
        end
    end
    
    function v = convertElement(x)
        v = x;
        if isinf(v) || isnan(v)
            v = num2str(v);
        end
    end
end

