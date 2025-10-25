function validateCustomReadFcn(readFcn, fromConstructor, datastoreName, ...
                               minInputArgs, minOutputArgs, fcnName)
%validateCustomReadFcn    Validator for custom read functions

%   Copyright 2015-2020 The MathWorks, Inc.
    if nargin < 6
        fcnName = 'ReadFcn';
    end
    
    if nargin < 5
        minOutputArgs = 1;
    end

    if nargin < 4
        minInputArgs = 1;
    end

    % validate that a function handle type is provided.
    if isa(readFcn, 'function_handle')

        % compute nargin/nargout with a try-catch to make sure that MEX 
        % functions can be used here too.
        try
            nInputs = nargin(readFcn);
            nOutputs = nargout(readFcn);
        catch ME
            if strcmp(ME.identifier, 'MATLAB:narginout:doesNotApply')
                % if the custom ReadFcn is a MEX function, we cannot do any
                % further validation, so just return here.
                return;
            else
                rethrow(ME);
            end
        end

        sufficientInputs =  (nInputs >= minInputArgs) ...
                         || (nInputs < 0); % enable varargin cases too.

        sufficientOutputs =  (nOutputs >= minOutputArgs) ...
                          || (nOutputs < 0); % enable varargout cases too.

        if sufficientInputs && sufficientOutputs
            return;
        end
    end

    % insufficient number of input or output arguments.
    if fromConstructor
        error(message('MATLAB:datastoreio:customreaddatastore:invalidReadFcnFromXtor', ...
            fcnName, minInputArgs, minOutputArgs, datastoreName));
    else
        error(message('MATLAB:datastoreio:customreaddatastore:invalidReadFcn', ...
            fcnName, minInputArgs, minOutputArgs));
    end
end
