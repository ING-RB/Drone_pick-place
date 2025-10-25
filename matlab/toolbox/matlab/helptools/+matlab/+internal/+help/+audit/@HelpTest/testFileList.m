function obj = testFileList(obj, fileList)
    %testFileList Runs runTests on list of files

    %   Copyright 2021 The MathWorks, Inc.

    for i = 1:numel(fileList)
        obj = runTests(obj, fileList(i));
    end
end
