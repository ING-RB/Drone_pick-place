function appendixText = getAppendixByGrammarName(fileContent, grammarName, rootElementName)
    %GETAPPENDIXBYGRAMMARNAME

%   Copyright 2024 The MathWorks, Inc.

    arguments
        fileContent string
        grammarName string
        rootElementName string
    end

    appendixText = '';

    grammarIdentifier = append('%[', grammarName, ']');

    startLocation = strfind(fileContent, grammarIdentifier);

    if ~isempty(startLocation)
        afterGrammarText = extractAfter(fileContent, startLocation + strlength(grammarIdentifier));

        openingBlockLocation = strfind(afterGrammarText, '%{');

        if length(openingBlockLocation) > 1
            openingBlockLocation = openingBlockLocation(1);
        end
        
        closingBlockComments = strfind(afterGrammarText, '%}');

        rootClosingLocation = strfind(afterGrammarText, append('</', rootElementName, '>'));

        if length(rootClosingLocation) > 1
            rootClosingLocation = rootClosingLocation(end);
        end

        closingCommentLocation = closingBlockComments(closingBlockComments > rootClosingLocation);

        if length(closingCommentLocation) > 1
            closingCommentLocation = closingCommentLocation(1);
        end

        appendixText = strtrim(extractBetween(afterGrammarText, openingBlockLocation + 2, closingCommentLocation - 2));
    end
end
