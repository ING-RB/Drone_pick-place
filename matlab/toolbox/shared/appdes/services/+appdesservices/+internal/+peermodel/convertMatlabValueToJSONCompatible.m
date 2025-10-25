function jsonCompatibleValue = convertMatlabValueToJSONCompatible( matlabValue , ignoreTypes)
% CONVERTMATLABVALUETOJSONCOMPATIBLE 
%
% Converts a MATLAB value to a value compatible with JSON, for exmaple,
% Inf/-Inf to char 'Inf'/'-Inf'

% Copyright 2017 The MathWorks, Inc.

    if nargin == 2 && any(strcmp(class(matlabValue), ignoreTypes))
        jsonCompatibleValue = matlabValue;
        return;
    end

    jsonCompatibleValue = matlabValue;
    if isstring(matlabValue)
        % Strings will be processed consistently with cell arrays of
        % strings
        
        jsonCompatibleValue = appdesservices.internal.peermodel.convertMatlabStringToJSONCompatible(matlabValue);                
    elseif isnumeric(matlabValue) && isreal(matlabValue)
        % convert Inf / -Inf to 'Inf' / '-Inf', and NaN to 'NaN'
        %
        jsonCompatibleValue = appdesservices.internal.peermodel.convertMatlabNumberToJSONCompatible(matlabValue);
    
    elseif isdatetime(matlabValue)
        jsonCompatibleValue = appdesservices.internal.peermodel.convertMatlabDateTimeToJSONCompatible(matlabValue);
   
    elseif isa(matlabValue, 'matlab.lang.OnOffSwitchState')
        jsonCompatibleValue = logical(matlabValue);
        
    elseif(isa(matlabValue,'struct'))
        % struct are converted into hash maps
        if(isscalar(matlabValue))            
            jsonCompatibleValue = convertStructToJSONCompatible(matlabValue);
        else
            [m,n] = size(matlabValue);            
            for j = 1:m
                for k = 1:n
                    jsonCompatibleValue(j,k) = convertStructToJSONCompatible(matlabValue(j,k));
                end
            end
		end
		
    elseif(isa(matlabValue, 'function_handle'))
        % convert function handle to a string
        jsonCompatibleValue = '';
        if ~isempty(matlabValue)
            % function_handle could be an empty value, which could not be
            % handled by func2str
            jsonCompatibleValue = func2str(matlabValue);
        end
        
    elseif(isMATLABValueNotSupported(matlabValue))
        % handle object is not supported by JSON
        jsonCompatibleValue = [];
    
    elseif(iscell(matlabValue))        
        [m,n] = size(matlabValue);
        for j = 1:m
            for k = 1:n
                jsonCompatibleValue{j,k} = appdesservices.internal.peermodel.convertMatlabValueToJSONCompatible(matlabValue{j,k});
            end
        end
        
    end
    
    function jsonCompatibleData = convertStructToJSONCompatible(structData)
        jsonCompatibleData = structData;
        
        % get the fields of the struct and loop over
        fields = fieldnames(jsonCompatibleData);
        
        pvPairs = {};
        for fieldIdx = 1:length(fields)
            fieldName = fields{fieldIdx};
            jsonCompatibleData.(fieldName) = ...
                viewmodel.internal.convertMatlabToJSONCompatible(jsonCompatibleData.(fieldName));
        end
    end

    % Here we maintain a list of matlab types that are not supported by
    % JSON encode or by alternative logic to convert to a json compatible type
    function isNotSupported = isMATLABValueNotSupported(matlabValue)
        isNotSupported = isa(matlabValue, 'handle') || isduration(matlabValue) || (isnumeric(matlabValue) && ~isreal(matlabValue));
    end
end

