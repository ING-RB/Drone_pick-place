function [docPage, source] = getExamplePageForId(exampleId)
    docPage = matlab.internal.doc.url.MwDocPage.empty;
    [examples, source] = matlab.internal.examples.getExampleDataForId(exampleId);
    if ~isempty(source)
        examples(arrayfun(@(ex) isempty(ex.RelativePaths), examples)) = [];
        if ~isempty(examples)
            docPage = matlab.internal.doc.url.MwDocPage;
            docPage.Product = examples(1).HelpFolder;
            docPage.RelativePath = examples(1).RelativePaths(1);
        end
    end
end