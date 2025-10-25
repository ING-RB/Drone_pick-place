function javaValue = convertMatlabValueToJavaValue( matlabValue )
% CONVERTMATLABVALUETOJAVAVALUE
% Converts a MATLAB value to a Java value

% Copyright 2015 - 2018 The MathWorks, Inc.

% g1811307: javaArray does not work well with row vectors as the array is
% treated as ragged.  Thus its size is reported as 1x1.
% When dealing with column vectors, the size is reported correctly.
if isrow(matlabValue) && ~isa(matlabValue, 'function_handle')
    matlabValue = matlabValue';
end

if(ischar(matlabValue) && (isvector(matlabValue) || isempty(matlabValue)))
    % strings are converted to java.lang.String
    % % '' needs to be converted explicity to a string, otherwise it
    % becomes null
    javaValue = java.lang.String(matlabValue);

elseif isnumeric(matlabValue)
    % numbers are converted to java.lang.Double
    javaValue = convertNumeric(matlabValue);

elseif(islogical(matlabValue))
    javaValue = convertLogical(matlabValue);

elseif(isstruct(matlabValue))
    javaValue = convertStruct(matlabValue);

elseif (isobject(matlabValue))
    javaValue = convertObject(matlabValue);

elseif(iscell(matlabValue))
    javaValue = convertCell(matlabValue);

elseif(isa(matlabValue, 'function_handle'))
    % convert function handle to a string
    if ~isempty(matlabValue)
        % function_handle could be an empty value, which could not be
        % handled by func2str
        javaValue = func2str(matlabValue);
    else
        javaValue = java.lang.String('');
    end

elseif(isa(matlabValue, 'handle'))
    [m,n] = size(matlabValue);
    javaValue = javaArray('java.lang.Double', m,n);

end

end

function javaValue = convertCell(matlabValue)
% cell is converted to java object array

if(isvector(matlabValue))
    % create a one dimensional java array
    javaValue = javaArray('java.lang.Object', length(matlabValue));
    for j = 1:length(matlabValue)
        javaValue(j) = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(matlabValue{j});
    end
else
    % create a multidimensional java array
    [m,n] = size(matlabValue);
    javaValue = javaArray('java.lang.Object', m,n);
    for j = 1:m
        for k = 1:n
            javaValue(j,k) = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(matlabValue{j,k});
        end
    end
end
end

function javaValue = convertObject(matlabValue)

% There are a collection of objects that will not be sent to the
% client as is
% There are no runtime or design time use cases where objects in general
% can be processed on the client. Eventually, the client will
% support these advanced types, and at this time, it will be
% important to create a separation for supported types

% Examples of these objects are things like:
% any MCOS handle object including graphics objects
% MCOS value objects like table or timeseries

% value is equivalent of [], which is converted to an java array

% An empty double is the most like this handle or object
if isstring(matlabValue)
    % Strings will be processed consistently with cell arrays of
    % strings
    javaValue = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(...
        appdesservices.internal.peermodel.convertMatlabStringToJSONCompatible(matlabValue));
elseif (istable(matlabValue))
    % The size of a table is the number of entries it has
    % for any table object, we'll send one empty double value.
    javaValue = javaArray('java.lang.Double', 1, 1);
elseif isdatetime(matlabValue)
    javaValue = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(...
        appdesservices.internal.peermodel.convertMatlabDateTimeToJSONCompatible(matlabValue));
elseif iscategorical(matlabValue)
    if numel(matlabValue) == 1
        javaValue = java.lang.String(char(matlabValue));
    else
        [m, n] = size(matlabValue);
        javaValue = javaArray('java.lang.Object', m, n);
        for j = 1:m
            for k = 1:n
                javaValue(j, k) = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(matlabValue(j, k));
            end
        end
    end
else
    [m,n] = size(matlabValue);
    javaValue = javaArray('java.lang.Double', m,n);
end
end

function javaValue = convertNumeric(matlabValue)
% numbers are converted to java.lang.Double

% This is being cast to a double because JAVA does not support
% types like uint8 etc.
matlabValue = double(matlabValue);

if (any(any(isinf(matlabValue))) || any(any(isnan(matlabValue))))
    % Add isinf and isnan checking to avoid infinite recursive calling
    % convert Inf/-Inf to 'Inf'/ '-Inf', or NaN to 'NaN'
    %
    % JSON does not handle Inf/-Inf or NaN
    jsonReadyValue = appdesservices.internal.peermodel.convertMatlabNumberToJSONCompatible(matlabValue);

    javaValue = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(jsonReadyValue);

elseif(isscalar(matlabValue))
    % Potentially this explicit casting to java.lanb.Double could be
    % reduced because of a new connector feature.   g1553543 captures
    % work to remove this special handling of numeric values.
    javaValue = java.lang.Double(matlabValue);
elseif(isvector(matlabValue) || isempty(matlabValue))
    % create a one dimensional java array
    javaValue = javaArray('java.lang.Double', length(matlabValue));
    for k = 1:length(matlabValue)
        javaValue(k) = java.lang.Double(matlabValue(k));
    end
else
    % create a multidimensional java array
    [m,n] = size(matlabValue);
    javaValue = javaArray('java.lang.Double', m,n);
    for j = 1:m
        for k = 1:n
            javaValue(j,k) = java.lang.Double(matlabValue(j,k));
        end
    end
end

end

function javaValue = convertLogical(matlabValue)
% logical is converted into boolean or char

if(isa(matlabValue, 'matlab.lang.OnOffSwitchState'))
    % cast OnOff to logical and then convert to java
    javaValue = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(logical(matlabValue));
elseif(isscalar(matlabValue))
    % logicals are converted to java.lang.Boolean
    javaValue = java.lang.Boolean(matlabValue);
elseif(isvector(matlabValue) || isempty(matlabValue))
    % create a one dimensional java array
    javaValue = javaArray('java.lang.Boolean', length(matlabValue));
    for k = 1:length(matlabValue)
        javaValue(k) = java.lang.Boolean(matlabValue(k));
    end
else
    % create a multidimensional java array
    [m,n] = size(matlabValue);
    javaValue = javaArray('java.lang.Boolean', m,n);
    for j = 1:m
        for k = 1:n
            javaValue(j,k) = java.lang.Boolean(matlabValue(j,k));
        end
    end
end
end

function javaValue = convertStruct(matlabValue)
% struct are converted into hash maps

if(isscalar(matlabValue))
    javaValue = appdesservices.internal.peermodel.convertStructToJavaMap(matlabValue);
elseif(isvector(matlabValue) || isempty(matlabValue))
    % Create a one dimensional java array of hash maps
    % Preallocate a HashMap array
    javaValue = javaArray('java.util.HashMap', length(matlabValue));
    for k = 1:length(matlabValue)
        javaValue(k) = appdesservices.internal.peermodel.convertStructToJavaMap(matlabValue(k));
    end
else
    % Create a multidimensional array of hash maps
    [m,n] = size(matlabValue);
    javaValue = javaArray('java.util.HashMap', m,n);
    for j = 1:m
        for k = 1:n
            javaValue(j,k) = appdesservices.internal.peermodel.convertStructToJavaMap(matlabValue(j,k));
        end
    end
end
end
