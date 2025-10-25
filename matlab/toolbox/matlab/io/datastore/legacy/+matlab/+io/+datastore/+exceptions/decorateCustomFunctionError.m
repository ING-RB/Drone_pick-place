% matlab.io.datastore.exceptions.decorateCustomFunctionError - an internal
% utility for FileDatastore, ImageDatastore, and AudioDatastore.

% Copyright 2019 The MathWorks, Inc.

function decorateCustomFunctionError(ME, functionHandle, filename, ...
                                     expectedNumOutputs, splitReaderClassName, methodName)
    %decorateCustomFunctionError - Helper utility that provides customized
    % error messages if an end user-provided function handle errors when
    % reading or previewing from a datastore.
    
    % If methodName is not provided, define it as "ReadFcn" by default.
    if nargin < 6
        methodName = "ReadFcn";
    end

    % Get a string representation of the function handle.
    functionString = string(func2str(functionHandle));

    % Prepend an @ to the function string if it isn't already present.
    if ~startsWith(functionString, "@")
        functionString = "@" + functionString;
    end

    % Provide a nicer error message if we know that the user's function has
    % errored due to an incorrect number of output arguments.
    tooManyOutputsErrorIdentifiers = ["MATLAB:maxlhs", "MATLAB:TooManyOutputs"];
    isTooManyOutputsError = any(ME.identifier == tooManyOutputsErrorIdentifiers);

    if isTooManyOutputsError && ~isempty(ME.stack)
        generateTooManyOutputsError(ME, functionString, expectedNumOutputs, ...
                                              splitReaderClassName, methodName);
    end

    % Remove internal datastore class names from the stack. Returns an
    % empty string if the error is entirely internal.
    stackText = trimInternalStack(ME, splitReaderClassName);

    % Throw an error with the 'cleaned' stack devoid of internal datastore
    % functions to reduce visual clutter.
    if ~isempty(stackText)
        generateReadFcnError(ME, stackText, functionString, filename, methodName);
    end

    % If the error doesn't match any of the special cases we can provide
    % help for, then rethrow it.
    throw(ME);
end

function generateTooManyOutputsError(ME, functionString, expectedNumOutputs, ...
                                              splitreaderClassName, methodName)

    % We need to ensure that the topmost function on the stack that
    % errored is one of our splitreaders. If this is not the case, then this
    % implies that a user's function errored internally and we'd want 
    % to avoid showing this error message suggestion.
    functionNameForError = ME.stack(1).name;

    % The first element's file is empty in the case of anonymous functions.
    isTopStackFunctionAnonymous = isempty(ME.stack(1).file);

    if isTopStackFunctionAnonymous && numel(ME.stack) > 1
        % Use the second element name, if the first element's name is
        % anonymous.
        functionNameForError = ME.stack(2).name;
    end

    % If the first element in the error stack is getNext() on one of our
    % splitreaders, then this means that the nargout of readFcn is
    % incorrect.
    if functionNameForError == splitreaderClassName + ".getNext"
        import matlab.io.datastore.exceptions.CustomReadException;
            
        msgid = 'MATLAB:datastoreio:customreaddatastore:noOutputReadFcn';
        msg = message(msgid, methodName, functionString, expectedNumOutputs);
        err = CustomReadException(ME, msgid, '%s', msg.getString());
        throw(err);
    end
end

function errorMessageText = trimInternalStack(e, splitReaderClassName)
    % Get the error message with the whole stack
    errorMessageText = getReport(e);
    % Find the start of the stack for getNext()
    idx = strfind(errorMessageText, splitReaderClassName);
    % Take the first match
    idx = idx(1);
    idx = regexp(errorMessageText(1:idx), '\n');
    % Take the last new line index
    if ~isempty(idx)
        idx = idx(end);
    end
    % Remove all stack beneath getNext()
    errorMessageText = strtrim(errorMessageText(1:idx));
end

function generateReadFcnError(ME, stackText, functionString, filename, methodName)
    import matlab.io.datastore.exceptions.CustomReadException;

    msgid = 'MATLAB:datastoreio:customreaddatastore:readFcnError';
    msg = message(msgid, methodName, functionString, filename, stackText);
    err = CustomReadException(ME, msgid, '%s', msg.getString());
    throw(err);
end