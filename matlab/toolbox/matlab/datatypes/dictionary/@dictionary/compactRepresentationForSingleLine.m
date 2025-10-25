function displayRep = compactRepresentationForSingleLine(d,dispConfig,maxWidth)
%

%   Copyright 2022-2023 The MathWorks, Inc.

    arguments
        d dictionary
        dispConfig (1,1) matlab.display.DisplayConfiguration
        maxWidth (1,1) double {mustBeReal, mustBePositive}
    end

    dictionaryCompactDiplay = buildCompactDispay(d,dispConfig,maxWidth);

    displayRep = widthConstrainedDataRepresentation(d, ...
                                                    dispConfig, ...
                                                    maxWidth, ...
                                                    AllowTruncatedDisplayForScalar=true,...
                                                    StringArray=dictionaryCompactDiplay, ...
                                                    TruncateScalarObject=true);
end

function result = buildCompactDispay(d,dispConfig,maxWidth)

    % Reduce width due to space needed for data delmiters
    maxWidth = maxWidth - sum(strlength(dispConfig.DataDelimiters));

    result = getDictionaryEntriesHeader(d,IncludeType=true);

    if dispConfig.characterWidthForStringArray(result) > maxWidth
        result = getDictionaryEntriesHeader(d,IncludeType=false);
    end

    if dispConfig.characterWidthForStringArray(result) > maxWidth
        result = "dictionary";
    end
end

function result = getDictionaryEntriesHeader(d,options)
    arguments
        d dictionary;
        options.IncludeTypes (1,1) logical;
    end

    if ~isConfigured(d)
        result = string(message("MATLAB:dictionary:WithUnsetKeyAndValueTypesContained","dictionary"));
    else

        messageArguments = {"dictionary"};

        if options.IncludeTypes
            [kType, vType] = types(d);
        
            kvTypes = compose("(%s %s %s)", kType, matlab.internal.dictionary.arrowCharacter, vType);
    
            messageArguments = [messageArguments {kvTypes}];
        end
        
        nEntries = numEntries(d);
    
        if nEntries > 1
            messageArguments = [messageArguments {nEntries}];
        end

        createDictionaryEntryHeader = @(id)getDictionaryEntryHeaderMessageText(id, options, messageArguments);

        if nEntries == 0
            result = createDictionaryEntryHeader("MATLAB:dictionary:WithZeroEntriesContained");
        elseif nEntries == 1
            result = createDictionaryEntryHeader("MATLAB:dictionary:WithOneEntryContained");
        else
            result = createDictionaryEntryHeader("MATLAB:dictionary:WithManyEntriesContained");
        end
    end
end

function result = getDictionaryEntryHeaderMessageText(id,options,messageArguments)

    if ~options.IncludeTypes
        id = id + "NoTypes";
    end

    result = message(id,messageArguments{:});
    result = string(result);
end
