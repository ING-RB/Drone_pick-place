%

% Copyright 2022-2023 The MathWorks, Inc.

function resObjs = createFromCodeCoverageCollectorData(staticData, runtimeData)

arguments
   staticData (1,:) cell
   runtimeData (:,1) uint64
end

% Convert the LXE coverage data to the mf0-based coverage result
codeCovDataObjImpls = matlab.coverage.internal.coverageCollectorDataToCodeCoverageData(staticData, runtimeData);

% Construct the output array of objects
resObjs(1:numel(codeCovDataObjImpls), 1) = matlab.coverage.Result();
for ii = 1:numel(resObjs)
    files = codeCovDataObjImpls{ii}.CodeTr.getFilesInCurrentModule();
    if files(1).status == "FAILED"
        warning(message('MATLAB:coverage:result:InvalidFileForCoverage', ...
            files(1).path));
    end
    codeCovDataObj = codeinstrum.internal.codecov.CodeCovData(codeCovDataObjImpls{ii});
    resObjs(ii) = matlab.coverage.Result(codeCovDataObj);
end

% LocalWords:  LXE mf
