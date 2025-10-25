function [examples, source] = getExampleDataForId(exampleId)
    examples = matlab.internal.example.api.ExampleData.empty;
    source = string.empty;

    match = regexp(exampleId,'^(\w+)[\\/-](\w+)$','tokens','once');
    if ~isempty(match)
        source = string(match{2});
        id = string(match{1}) + "-" + string(match{2});
        examples = matlab.internal.example.api.FindExampleData(id);
    end
end

