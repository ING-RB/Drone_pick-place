function translatedCatalogStrings = CustomContextMenui18nRequestHandler(catalogEntries)
    % CustomContextMenui18nRequestHandler: This function is a wrapped around
    % getString(message(...)) so that we cna query the message catalog using an
    % FEval. 
    % TODO: Remove this when registration frameworks support for i18n arrives
    
    % Copyright 2021 The MathWorks, Inc.
    
    % Loop over the array of catalog entries and get the translated strings
    translatedCatalogStrings = cellfun(@(x) getString(message(x)), catalogEntries, 'UniformOutput', false);
end

