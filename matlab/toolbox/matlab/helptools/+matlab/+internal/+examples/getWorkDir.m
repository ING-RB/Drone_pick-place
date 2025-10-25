function workDir = getWorkDir(metadata)
%

%   Copyright 2020-2022 The MathWorks, Inc.

    ed = matlab.internal.examples.getExamplesDir();
    if isfield(metadata, 'workFolder')
        workDir = fullfile(ed, metadata.component, metadata.workFolder);
    else
        workDir = fullfile(ed, metadata.component, metadata.main);
    end
end
