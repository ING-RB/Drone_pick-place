function examples = findExamples(supportingFile)
%

%   Copyright 2018-2023 The MathWorks, Inc.

    [~, ~, ext] = fileparts(supportingFile);

    exampleTitle = 'exampleTitle';
    exampleId = 'exampleId';
    examples = struct(exampleTitle, {}, exampleId, {});
    exampleData = matlab.internal.example.api.FindExampleDataForSupportingFile(supportingFile);
    try
        if ~isempty(exampleData)
            for index = 1:numel(exampleData)
                if strlength(ext) > 0 || isExecutableSupportingFile(exampleData(index), supportingFile)
                    examples(end+1) = struct(exampleTitle, char(exampleData(index).Title), ...
                        exampleId, char(exampleData(index).getID())); %#ok<AGROW>
                end
            end
            if ~isempty(examples)
                [~,ind] = unique({examples.exampleId});
                examples = examples(ind);
            end
        end
    catch
    end
end

function isExecutable = isExecutableSupportingFile(exampleData, supportingFile)
    isExecutable = false;
    [~, supportingFileName] = fileparts(supportingFile);
    if supportingFileName == exampleData.Name
        isExecutable = true;
        return;
    end
    
    for iFiles = 1:numel(exampleData.SupportingFiles)
        filename = exampleData.SupportingFiles{iFiles};
        [~, name, ext] = fileparts(filename);
        if strcmp(supportingFileName, name)
            if strcmp(ext, '.m') || strcmp(ext, '.mlx') || strcmp(ext, '.slx')
                isExecutable = true;
                break;
            end
        end
    end
end

% LocalWords:  mlx
