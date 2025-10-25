function matlabValue = convertJSONCompatibleValueToMatlabValue(jsonCompatibleValue)
% CONVERTJAVAVALUETOMATLABVALUE 
% Converts a Java value to a MATLAB value

% Copyright 2017 - 2020 The MathWorks, Inc.
    
    % Convert values
    matlabValue = jsonCompatibleValue;
    
    % datetime values handled by viewmodel.internal.convertJSONCompatibleToMatlab,
    % which wraps this function

    if isstruct(matlabValue)
        if (isscalar(matlabValue))
            matlabValue = appdesservices.internal.peermodel.convertJSONCompatibleStructToStruct(matlabValue);
        else
            [m,n] = size(matlabValue);
            for j = 1:m
                for k = 1:n
                    matlabValue(j,k) = appdesservices.internal.peermodel.convertJSONCompatibleStructToStruct(matlabValue(j,k));
                end
            end
        end
        % We only need to transpose if there is more than one element
    elseif iscolumn(matlabValue) && ~isscalar(matlabValue)
        matlabValue = matlabValue';        
    end

end
