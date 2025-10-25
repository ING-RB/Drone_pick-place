function obj = runTests(obj, file)
    %runTests runs help audit tests on worklist
    %   A = runTests(A, fileName)
    %   Takes in a HelpTest object and the file on which to run the tests

    %   Copyright 2021-2024 The MathWorks, Inc.
    fileResult = matlab.internal.help.audit.FileInformation(file);
    tests = fieldnames(obj.CurrentTestSettings);
    for i = 1:numel(tests)
        if obj.CurrentTestSettings.(tests{i}) && fileResult.HelpText ~= ""
            testName = tests{i};
            testName(1) = lower(testName(1));
            fileResult = feval(testName, fileResult);
        end
    end
    obj.Results = [obj.Results, fileResult];
end

