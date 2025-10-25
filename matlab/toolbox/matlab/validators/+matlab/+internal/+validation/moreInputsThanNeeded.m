function E = moreInputsThanNeeded(...
        functionName, callSiteInfo, userArgs, validArgs)   
%

%   Copyright 2019-2024 The MathWorks, Inc.

    numRequired = sum([validArgs.required]);
    errorID = 'MATLAB:TooManyInputs';

    includeImmutables = false;
    namedClass = getNamedClass(validArgs);
    if ~isempty(namedClass)
        % includeImmutables uses caller context when resolving namedClass and the construtor's class
        includeImmutables = matlab.internal.validation.includeImmutables(namedClass);
    end

    try % ignore exceptions that can be caused by future FE changes and other unhandled exceptions.
        if canErrorBeSpecific(validArgs)

            % MCOS-8653
            if matlab.internal.validation.ExecutionContextWrapper.hasPackagesFeature
                callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper(matlab.lang.internal.ExecutionContext.caller);
            else
                callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper;
            end

            % We only specialize error messages for functions with declared name-value arguments, with no repeating arguments
            [numOfRequired, numOfOptional, validNames, displayableNames] = getArgsInfo(validArgs, callerContextWrapper, includeImmutables);

            % handle special case where the class from opts.?class doesn't have public settable properties 
            if numel(userArgs) > 0 && numOfRequired == 0 && numOfOptional == 0 && isempty(validNames)
                className = [validArgs.namedclass];
                assert(~isempty(className));
                errorMessage = message(...
                    'MATLAB:functionValidation:ClassWithoutPublicSettableProperty',...
                    functionName, className).getString;
                E = matlab.internal.validation.RuntimeInputsException.createInputsExceptionUsingIDAndMessage(...
                    functionName,...
                    numRequired,...
                    errorID,...
                    errorMessage);
                return;
            end

            E = generateSpecificErrors(functionName, callSiteInfo, userArgs,...
                                       numOfRequired, numOfOptional, validNames, displayableNames);
            if ~isempty(E)
                return;
            end
        end
    end
    
    errorMessage = message('MATLAB:functionValidation:TooManyInputsGenericMessage').getString;
    
    E = matlab.internal.validation.RuntimeInputsException.createInputsExceptionUsingIDAndMessage(...
        functionName,...
        numRequired,...
        errorID,...
        errorMessage);
end

function E = generateSpecificErrors(functionName, callSiteInfo,...
                                    inputs, numOfRequired, numOfOptional, validNames, displayableNames)
    import matlab.internal.validation.Exception.genFormatedValuesForNamedArguments
    
    % ONLY use this error ID to create exceptions
    tooManyInputsErrorID = 'MATLAB:TooManyInputs';
    
    nameExpectedMsgID = 'MATLAB:functionValidation:NameExpected';
    nameValueNotInPairsMsgID = 'MATLAB:functionValidation:NameValueNotInPairs';
    
    E = [];
    inputErrorFcn = @matlab.internal.validation.RuntimeInputsException.createInputsExceptionUsingIDAndMessage;
    namedErrorFcn = @matlab.internal.validation.RuntimeNameValueException.createExceptionForUnrecognizedName;
    positionErrorFcn = @matlab.internal.validation.RuntimePositionalException.createExceptionUsingIDAndMessage;
    nargs = numel(inputs);

    % There should be no ambiguous error; otherwise, we'd have stopped in
    % the transformation function. We go all the way from right to left
    % again until we reach the place where the error happens.
    isLastAScalarText = false;
    isLastAMatch = false;
    numberOfUnparsed = nargs;
    argumentPosition = 1;
        
    if (nargs > 1)
        for argumentPosition=nargs-1:-2:numOfRequired
            pname = inputs{argumentPosition};
            if ~isScalarText(pname)
                isLastAScalarText = false;
                isLastAMatch = false;
                break;
            end
            
            isLastAScalarText = true;
            isLastAMatch = any(startsWith(validNames,pname,'IgnoreCase',1));
            if ~isLastAMatch
                break;
            end
        end
        
        if isLastAMatch
            numberOfUnparsed = argumentPosition-1;
        else
            numberOfUnparsed = argumentPosition+1;
        end
    end
    
    % meanings of letters and marker in condition comments:
    % r = required
    % o = optional
    % n = valid name
    % nv = valid name-value pair
    % s = valid scalar text but not valid name
    % v = not valid scalar text, possibly a value
    % ^ error position
    if isLastAMatch
        % condition: f(r,r,^n)
        argumentName = inputs{argumentPosition};
        assert(numberOfUnparsed < numOfRequired);
        errorMsg = message(...
            'MATLAB:functionValidation:WrongNumberOfRequiredWithFollowingNameValueArguments',...
            numOfRequired, argumentName).getString;
        E = positionErrorFcn(...
            functionName,...
            callSiteInfo,...
            argumentPosition,...
            argumentName,...
            tooManyInputsErrorID,...
            errorMsg);
        return;
    else
        % parse doesn't end with a match
        if numberOfUnparsed > numOfRequired + numOfOptional
            if numOfOptional == 0
                % if no valid scalar text exists in the range of
                % (numOfRequired, nargs], the message can be optimized
                % before checking misspelled names and n-v misalignments
                tfScalarText = false;
                for argumentPosition = numOfRequired+1:nargs
                    if isScalarText(inputs{argumentPosition})
                        tfScalarText = true;
                        break;
                    end
                end
                
                if ~tfScalarText && numOfRequired > 0
                    % condition: f(r,^v,v)
                    % issue "Function requires exactly
                    % numOfRequired positional input(s)."
                    argumentPosition = numOfRequired+1;
                    argumentName = '';
                    errorMsg = message(...
                        'MATLAB:functionValidation:TooManyRequiredWithoutFollowingScalarText',...
                        numOfRequired).getString;
                    E = positionErrorFcn(...
                        functionName,...
                        callSiteInfo,...
                        argumentPosition,...
                        argumentName,...
                        tooManyInputsErrorID,...
                        errorMsg);
                    return;
                elseif numberOfUnparsed+1 < nargs && argumentPosition == numberOfUnparsed+1
                    % condition: f(r,^v,nv)
                    % issue "Function requires exactly
                    % numOfRequired positional input(s) before name 'n'."
                    anchorName = inputs{numberOfUnparsed+1};
                    argumentPosition = numOfRequired+1;
                    argumentName = '';
                    errorMsg = message(...
                        'MATLAB:functionValidation:TooManyRequiredWithFollowingNameValueArguments',...
                        numOfRequired, anchorName).getString;
                    E = positionErrorFcn(...
                        functionName,...
                        callSiteInfo,...
                        argumentPosition,...
                        argumentName,...
                        tooManyInputsErrorID,...
                        errorMsg);
                    return;
                end
                
                % we can issue a better error message by looking forward if
                % function doesn't accept optional inputs.
                for argumentPosition = (numOfRequired + 1):2:nargs
                    argumentName = inputs{argumentPosition};
                    if argumentPosition == nargs
                        if isScalarText(argumentName)
                            % condition: f(r,nv,nv,^s)
                            % name-value not in pairs is more appropriate
                            E = positionErrorFcn(...
                                functionName,...
                                callSiteInfo,...
                                argumentPosition,...
                                argumentName,...
                                tooManyInputsErrorID,...
                                message(nameValueNotInPairsMsgID).getString);
                            return;                           
                        else
                            % condition: f(r,nv,nv,^v)
                            % expect name error is more appropriate
                            argumentName = '';
                            E = positionErrorFcn(...
                                functionName,...
                                callSiteInfo,...
                                argumentPosition,...
                                argumentName,...
                                tooManyInputsErrorID,...
                                message(nameExpectedMsgID).getString);
                            return;
                        end
                    elseif isScalarText(argumentName)
                        if sum(startsWith(validNames,argumentName,'IgnoreCase',1)) == 0
                            % condition: f(r,nv,^sv)
                            % misspelled name
                            E = namedErrorFcn(...
                                functionName,...
                                callSiteInfo,...
                                argumentPosition,...
                                argumentName,...
                                tooManyInputsErrorID,...
                                displayableNames);
                            return;
                        else
                            continue;
                        end
                    else
                        % condition: f(r,nv,^v,nv)
                        % expect name
                        argumentName = '';
                        E = positionErrorFcn(...
                            functionName,...
                            callSiteInfo,...
                            argumentPosition,...
                            argumentName,...
                            tooManyInputsErrorID,...
                            message(nameExpectedMsgID).getString);
                        return;
                    end
                end
            else
                if isLastAScalarText
                    % condition: f(r,o,sv,^nv)
                    % If n-v pair parse stops at a text spot in the range of
                    % (numOfRequired, ...), issue a misspelled error.
                    % This error is more certain than others in the most common workflows.
                    % It is possible the user needs to fix other errors once this one is corrected.
                    argumentName = inputs{argumentPosition};
                    E = namedErrorFcn(...
                        functionName,...
                        callSiteInfo,...
                        argumentPosition,...
                        argumentName,...
                        tooManyInputsErrorID,...
                        displayableNames);
                    return;
                end
            
                % Determine whether caller provides too many positional
                % inputs by looking at inputs in range [numOfRequired + 1,
                % numOfRequired + numOfOptional + 1]
                % If none is a valid name in this range, then it is likely the case;
                % otherwise name-value are not provided in pairs
                tfName = false;
                for argumentPosition=numOfRequired+1:numOfRequired+numOfOptional+1
                    if isScalarText(inputs{argumentPosition})...
                            && sum(startsWith(validNames,inputs{argumentPosition},'IgnoreCase',1)) >= 1
                        tfName = true;
                        break;
                    end
                end
                
                if tfName
                    % condition: f(r,nv,^v), or f(r,o,nv,^v)
                    E = inputErrorFcn(...
                        functionName,...
                        argumentPosition,...
                        tooManyInputsErrorID,...
                        message(nameValueNotInPairsMsgID).getString);
                    return;
                elseif numberOfUnparsed+1 < nargs
                    % condition: f(r,o,^v,nv)
                    % anchor the error using the name before the error
                    % position if function call provides nv pairs
                    argumentName = inputs{numberOfUnparsed+1};
                    errorMsg = message(...
                        'MATLAB:functionValidation:TooManyOptionalWithFollowingNameValueArguments',...
                        numOfRequired, numOfRequired+numOfOptional, argumentName).getString;
                    E = positionErrorFcn(...
                        functionName,...
                        callSiteInfo,...
                        numOfRequired+numOfOptional+1,...
                        argumentName,...
                        tooManyInputsErrorID,...
                        errorMsg);
                    return;
                else
                    % condition: f(r,o,^v,...)
                    % otherwise, print the postion of the firt outlier
                    argumentName = '';
                    errorMsg = message(...
                        'MATLAB:functionValidation:TooManyOptionalWithoutFollowingNameValueArguments',...
                        numOfRequired, numOfRequired+numOfOptional).getString;
                    E = positionErrorFcn(...
                        functionName,...
                        callSiteInfo,...
                        numOfRequired+numOfOptional+1,...
                        argumentName,...
                        tooManyInputsErrorID,...
                        errorMsg);
                    return;
                end
            end
        else
            % should've been handled by tranformation
            throwUnhandledException;
        end
    end
end

% Only handle FV without repeating arguments
function tf = canErrorBeSpecific(metadata)
    tf = ~any([metadata.repeating])...
         && (~isempty([metadata.namedfield])...
             || ~isempty([metadata.namedclass]));
end

%% resolvedNamedClass is MyClsas in .?MyClass syntax. Empty if the syntax is not used, or MyClass fails to resolve.
function [numOfRequired, numOfOptional, validNames, displayableNames] = getArgsInfo(metadata, caller, includeImmutables)
    numOfRequired = sum([metadata.required]);
    numOfOptional = sum([metadata.optional]);

    % Get displayable named arguments
    validNames = strings(1,5); % simple preallocation
    displayableNames = strings(1,5); % simple preallocation
    idx = 1; vdx = 1;
    
    for i=1:numel(metadata)
        vd = metadata(i);
        name = vd.namedfield;
        if ~isempty(name)
            validNames(idx) = name;
            displayableNames(vdx) = name;
            idx = idx+1;
            vdx = vdx+1;
            continue;
        end

        namedclass = vd.namedclass;
        if ~isempty(namedclass)
            resolvedNamedClass = caller.resolveClass(namedclass);
            if isempty(resolvedNamedClass)
                continue;
            end

            mc = meta.class.fromName(resolvedNamedClass);
            if isempty(mc)
                continue;
            end
            [settables, visibles] = builtin("_get_public_settable_and_visible_properties", mc, includeImmutables);
            for j=1:numel(settables)
                validNames(idx) = settables(j);
                idx = idx + 1;
            end

            for j=1:numel(visibles)
                displayableNames(vdx) = visibles(j);
                vdx = vdx + 1;
            end 
            continue;
        end
    end
    
    validNames = unique(validNames, "stable");
    validNames = validNames(validNames~="");
    if vdx == 1
        displayableNames = validNames;
    else 
        displayableNames = unique(displayableNames, "stable");
        displayableNames = displayableNames(displayableNames~="");
    end
end

function tf = isScalarText(pname)
    tf = isvarname(pname) || iskeyword(pname);
end

function throwUnhandledException
    throw(MException('MATLAB:functionValidation:UnhandledException', 'UnhandledException'));
end

function namedClass = getNamedClass(metadata)
    names = string({metadata.namedclass});
    namedClass = names(names ~= "");   
end