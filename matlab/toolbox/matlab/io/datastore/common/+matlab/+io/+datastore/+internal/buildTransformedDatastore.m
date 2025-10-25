function tds = buildTransformedDatastore(varargin)
%buildTransformedDatastore   Performs NV-pair parsing to generate a 
%   TransformedDatastore with the correct IncludeInfo values.

%   Copyright 2020 The MathWorks, Inc.

    % Fewer than 2 inputs, throw an error
    narginchk(2, Inf);
    % Find the position of the function handle input.
    import matlab.io.datastore.internal.functor.isConvertibleToFunctionObject
    functionHandleMask = cellfun(@isConvertibleToFunctionObject, varargin);
    functionHandleIndex = find(functionHandleMask);

    % Verify that only a single transformation function was supplied
    if isempty(functionHandleIndex)
        % No transformation function was provided through input.
        msgid = "MATLAB:datastoreio:transformeddatastore:noTransformFuncFound";
        error(message(msgid));
    elseif  numel(functionHandleIndex) > 1
        % Multiple function handles were passed in as input.
        msgId = "MATLAB:datastoreio:transformeddatastore:multipleTransformFunc";
        error(message(msgId));
    end

    % Get the transformation function.
    fcn = varargin{functionHandleIndex};

    % Find the positions of the scalar string inputs. These are possible
    % NV pairs.
    parameterMask = cellfun(@isStringOrCharScalar, varargin);
    parameterIndices = find(parameterMask);

    if isempty(parameterIndices)
        nvPairIndices = [];
    else
        % Provide a nice error message if a string parameter does not match a recognized
        % NV pair name.
        nvPairIndices = throwIfUnrecognizedStringParameter(parameterIndices, varargin);
        if nvPairIndices < nargin
            nvPairIndices = nvPairIndices(1) : nvPairIndices(1)+1;
        else
            error(message("MATLAB:InputParser:ParamMissingValue", varargin{nvPairIndices(1)}));
        end
    end

    % Parse NV pairs from the first string parameter onwards.
    includeInfo = parseIncludeInfo(varargin(nvPairIndices));

    % Find the positions of the datastore inputs.
    datastoreIndices = setdiff(1:nargin, [functionHandleIndex, nvPairIndices]);

    % Error if all input datastores are not datastore subclasses.
    datastores = varargin(datastoreIndices);
    datastoreMask = cellfun(@isDatastore, datastores);
    if ~all(datastoreMask)
        error(message("MATLAB:InputParser:ParamMustBeChar"));
    end

    % If there's only one datastore, unwrap the cell array to fall
    % back to the old transform code path.
    if numel(datastores) == 1
        datastores = datastores{1};
    end

    tds = matlab.io.datastore.TransformedDatastore(datastores, fcn, ...
        includeInfo);

end % function buildTransformedDatastore

function tf = isDatastore(x)
    tf = isa(x, "matlab.io.Datastore") ...
       || isa(x, "matlab.io.datastore.Datastore");
end

function validList = throwIfUnrecognizedStringParameter(parameterIndices, args)
    % Validate that all scalar string parameters match recognized
    % parameter names.
    knownParameterNames = "IncludeInfo";
    validList = zeros(1, numel(parameterIndices));
    for ii = 1 : length(parameterIndices)
        thisParamName = string(args{parameterIndices(ii)});
        if ~contains(knownParameterNames, thisParamName)
            % unknown NV pair specified
            error(message("MATLAB:InputParser:UnmatchedParameter", ...
                thisParamName, ""));
        elseif all(validList == 0)
            validList(ii) = parameterIndices(ii);
        else
            % unknown NV pair specified
            error(message("MATLAB:InputParser:UnmatchedParameter", ...
                thisParamName, ""));
        end
    end
end

function tf = isStringOrCharScalar(arg)
    % Function that checks that for both string and char inputs
    tf = isStringScalar(arg) || ischar(arg);
end

function includeInfo = parseIncludeInfo(args)
    persistent pTransform;
    if isempty(pTransform)
        pTransform = inputParser();
        pTransform.addParameter('IncludeInfo', false, @(v) islogical(v) || isnumeric(v));
    end
    parse(pTransform, args{:});
    includeInfo = logical(pTransform.Results.IncludeInfo);
end
