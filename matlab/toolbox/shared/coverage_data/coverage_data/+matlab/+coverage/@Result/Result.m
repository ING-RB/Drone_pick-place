% Result - Result of code coverage
%
%   The matlab.coverage.Result class provides the result of code coverage
%   analysis for a source file. The file can contain MATLAB code or C/C++ code
%   generated with MATLAB Coder (TM).
%
%   Result properties:
%       Filename      - Name of the file corresponding to the result
%       CreationDate  - Date result was created
%       Filter        - Justifications applied to the result
%
%   Result methods:
%       generateHTMLReport      - Generate HTML coverage report from coverage results
%       generateCoberturaReport - Generate Cobertura XML coverage report from coverage results
%       coverageSummary         - Retrieve coverage information from coverage results
%       applyFilter             - Apply justifications to coverage results
%       resetFilter             - Remove justifications from coverage results
%
%   Result specialized MATLAB operators:
%       plus          - Return the union of two sets of results (the aggregated coverage)
%       minus         - Return the difference between two sets of results
%       mtimes, times - Return the intersection between two sets of results
%
%   Example:
%
%       import matlab.unittest.plugins.CodeCoveragePlugin
%       import matlab.unittest.plugins.codecoverage.CoverageResult
%
%       % Create an instance of the CoverageResult class
%       format = CoverageResult();
%
%       % Create a CodeCoveragePlugin instance using the CoverageResult format
%       plugin = CodeCoveragePlugin.forFile("C:\projects\myproj\foo.m", ...
%            Producing=format);
%
%       % Create a test runner, configure it with the plugin, and run the tests
%       runner = testrunner;
%       runner.addPlugin(plugin)
%       runner.run(testsuite("C:\projects\myproj\tests\testFoo.m"));
%
%       % Access coverage results programmatically
%       results = format.Result
%
%   See also: matlab.unittest.plugins.CodeCoveragePlugin,
%             matlab.unittest.plugins.codecoverage.CoverageResult
%

% Copyright 2022-2024 The MathWorks, Inc.

classdef (SupportExtensionMethods) Result < matlab.mixin.CustomDisplay

    properties (GetAccess=public, SetAccess=private, Dependent)
        % Filename - Name of the file corresponding to the result
        %   Name of the file corresponding to the coverage result, returned as a
        %   string scalar. MATLAB sets the property to the full path to
        %   the file when generating the coverage result.
        Filename string

        % CreationDate - Date result was created
        %   Date the result was created, returned as a datetime scalar.
        CreationDate datetime
    end

    properties (GetAccess=public, SetAccess=protected)
        % Filter - Justifications applied to the result
        Filter
    end

    properties (GetAccess=public, SetAccess=private, Dependent, Hidden)
        % Metadata - Additional information about the file
        %   Additional information about the file, such as the file size
        %   and last modification date, returned as a structure.
        Metadata struct

        % Invalid - Whether file is invalid
        %   Whether the file is invalid, returned as true or false.
        %   An invalid file is a file that MATLAB cannot run (for example,
        %   a file that contains syntax errors).
        Invalid logical

        % Settings - Coverage settings
        %   Settings of the coverage collection session, returned as a structure.
        Settings struct

        UniqueId (1,1) string
        StructuralChecksum (1,1) string
    end

    properties (GetAccess=public, SetAccess=private, Hidden)
        ExecutionMode (1,1) string = "Unknown"
        IsDerivedData (1,1) logical = false
        CodeCovData codeinstrum.internal.codecov.CodeCovData {mustBeScalarOrEmpty} = codeinstrum.internal.codecov.CodeCovData.empty()
    end

    methods (Hidden)
        %% Method: Result -------------------------------------------------
        %  Abstract:
        %    Constructor
        function this = Result(codeCovData)
            arguments
                codeCovData codeinstrum.internal.codecov.CodeCovData {mustBeScalarOrEmpty} = codeinstrum.internal.codecov.CodeCovData.empty()
            end
            if ~isempty(codeCovData)
                this.CodeCovData = codeCovData;
                if exist('matlabtest.coverage.Justification','class')
                    this.Filter = matlabtest.coverage.Justification.fromFilterData(this);
                end
            end
        end

        %% Method: getKey -------------------------------------------------
        %  Abstract:
        %    Return the unique key for identifying this result
        function value = getKey(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = "";
            fileObj = getFileObj(this);
            if ~isempty(fileObj)
                path = string(fileObj.pathRelativeToSymbolicName);
                mode = this.CodeCovData.CodeCovDataImpl.Mode;
                if mode == "MATLAB"
                    cksum = string(fileObj.checksum);
                else
                    cksum = string(sprintf('%02X', fileObj.structuralChecksum.toArray()));
                end
                value = path + string(mode) + cksum;
            end
        end
    end

    methods
        %% Method: get.Filter ------------------------------------------
        %  Abstract:
        %    Return the coverage filters
        function filter = get.Filter(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            filter = getFilter(this, this.Filter);
        end

        %% Method: get.Settings -------------------------------------------
        %  Abstract:
        %    Return the coverage settings
        function cfg = get.Settings(this)
            if isempty(this.CodeCovData)
                cfg = repmat(cfgStruct(), [0 0]);
            else
                % Create and populate the Settings object
                cfg = cfgStruct();
                codeCovDataImpl = this.CodeCovData.CodeCovDataImpl;
                cfg.Statement = codeCovDataImpl.isActive(internal.cxxfe.instrum.MetricKind.STATEMENT);
                cfg.Function = codeCovDataImpl.isActive(internal.cxxfe.instrum.MetricKind.FUN_ENTRY);
                cfg.Decision = codeCovDataImpl.isActive(internal.cxxfe.instrum.MetricKind.DECISION);
                cfg.Condition = codeCovDataImpl.isActive(internal.cxxfe.instrum.MetricKind.CONDITION);
                cfg.MCDC = codeCovDataImpl.isActive(internal.cxxfe.instrum.MetricKind.MCDC);
                if codeCovDataImpl.MCDCMode == internal.codecov.MCDCMode.MASKING
                    cfg.MCDCMode = "Masking";
                else
                    cfg.MCDCMode = "UniqueCause";
                end
            end
            % Don't expose the class matlab.coverage.Settings for now, then
            % convert the property to a struct
            function out = cfgStruct()
                fieldNames = properties("matlab.coverage.Settings");
                fieldValues = cell(1, numel(fieldNames));
                out = cell2struct(fieldValues, fieldNames, 2);
            end
        end

        %% Method: get.Filename -------------------------------------------
        %  Abstract:
        %    Return the name of the file corresponding to this result
        function value = get.Filename(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = string.empty;
            fileObj = getFileObj(this);
            if ~isempty(fileObj)
                value = string(fileObj.pathRelativeToSymbolicName);
            end
        end

        %% Method: get.Metadata -------------------------------------------
        %  Abstract:
        %    Return the structure containing additional information about the file
        function value = get.Metadata(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = struct('LastModifiedTime', {}, 'Size', {});
            try
                fileObj = getFileObj(this);
                if ~isempty(fileObj)
                    value = struct('LastModifiedTime', datetime(fileObj.lastModifiedTime), ...
                        'Size', fileObj.fileSize);
                end
            catch
            end
        end

        %% Method: get.CreationDate ---------------------------------------
        %  Abstract:
        %    Return the date of analysis
        function value = get.CreationDate(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = datetime.empty;
            if this.valid()
                try
                    value = datetime(this.CodeCovData.CodeCovDataImpl.CodeCovDataCore.endTime);
                catch
                end
            end
        end

        %% Method: get.UniqueId -------------------------------------------
        %  Abstract:
        %    Return the internal unique identifier
        function value = get.UniqueId(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = string.empty;
            if this.valid()
                value = string(this.CodeCovData.CodeCovDataImpl.CodeCovDataCore.UUID);
            end
        end

        %% Method: get.ExecutionMode --------------------------------------
        %  Abstract:
        %    Return the execution mode used for getting this result
        function value = get.ExecutionMode(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = "Unknown";
            if this.valid()
                value = string(this.CodeCovData.CodeCovDataImpl.Mode);
            end
        end

        %% Method: get.StructuralChecksum ---------------------------------
        %  Abstract:
        %    Return the structural checksum of this file
        function value = get.StructuralChecksum(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = string.empty;
            fileObj = getFileObj(this);
            if ~isempty(fileObj)
                if fileObj.structuralChecksum.Size() > 0
                    value = string(sprintf('%02X', fileObj.structuralChecksum.toArray()));
                else
                    value = string(fileObj.checksum);
                end
            end
        end

        %% Method: get.Invalid --------------------------------------------
        %  Abstract:
        %    Return true if the result is invalid, false otherwise
        function value = get.Invalid(this)
            arguments
                this (1,1) matlab.coverage.Result
            end
            value = true;
            if this.valid()
                fileObj = getFileObj(this);
                if ~isempty(fileObj)
                    value = fileObj.status == "FAILED";
                end
            end
        end
    end

    methods (Access=public)
        varargout = coverageSummary(resObj, metricName)
    end

    methods (Hidden)
        %% Method: valid --------------------------------------------------
        %  Abstract:
        %    Test if the current object is valid
        function value = valid(this)
            arguments
                this (:,1) matlab.coverage.Result
            end
            if isscalar(this)
                value = ~isempty(this.CodeCovData);
            else
                value = false(size(this));
                for ii = 1:numel(this)
                    value(ii) = ~isempty(this(ii).CodeCovData);
                end
            end
        end

        %% Method: checkCompatibility -------------------------------------
        %  Abstract:
        %    Test if the results are compatibles
        varargout = checkCompatibility(this, others)

        varargout = coverageSummaryInternal(resObj, metricName, options)
    end

    methods(Hidden, Access = protected)
        % Override of the matlab.mixin.CustomDisplay hook method
        groups = getPropertyGroups(resObj)

        % Override of the matlab.mixin.CustomDisplay hook method
        footerStr = getFooter(resObj)

        filter = getFilter(resObj, resObjFilters)
    end

    methods (Static, Access=protected, Hidden)
        res = performOp(lhs, rhs, op)
        res = createDerivedData(lhsObj, rhsObj, op)
        [staticData, runtimeData] = createCodeCoverageCollectorData(resObj, options)
    end

    methods (Hidden, Access = protected)
        function filteredObjArray = filterResultsForDuplicateSourceFiles(resObjArray)
            if isempty([resObjArray.Filename])
                filteredObjArray = resObjArray;
                return;
            end
            resObjArray = removeResultsWithEmptyData(resObjArray);
            [uniqueFileNames,uniqueIndices] = unique([resObjArray.Filename]);
            if numel(uniqueFileNames) == numel(resObjArray) % most common scenario 
                filteredObjArray = resObjArray;
            else

                filteredObjArray = cell(1,numel(uniqueIndices));
                for idx = uniqueIndices(:).'
                    resultsWithRepeatedFilename = resObjArray([resObjArray.Filename] == resObjArray(idx).Filename);
                    [~,sortedResultIdx] = sort([resultsWithRepeatedFilename.CreationDate]);
                    uniqueResult = resultsWithRepeatedFilename((sortedResultIdx(end)));
                    filteredObjArray{idx} = uniqueResult;
                end
                filteredObjArray = [filteredObjArray{:}];
            end
        end
    end

    methods (Hidden)
        function res = clone(this)
            res = matlab.coverage.Result(this.CodeCovData.clone());
        end

        function res = addFilter(this, uuid, outcomeIdx, filterMode, rationale)
            ccvd = this.CodeCovData.CodeCovDataImpl;
            elem = getFilteredElement(ccvd, uuid, outcomeIdx);
            if isempty(elem)
                res = false;
            else
                % "excluded"|"justified" -> internal.codecov.FilterMode.EXCLUDED|internal.codecov.FilterMode.JUSTIFIED
                filterMode = internal.codecov.FilterMode(upper(filterMode));
                res = ccvd.addFilter(1, internal.codecov.FilterSource.USER, filterMode, rationale, elem);
            end
        end

        function res = removeFilter(this, uuid, outcomeIdx)
            ccvd = this.CodeCovData.CodeCovDataImpl;
            elem = getFilteredElement(ccvd, uuid, outcomeIdx);
            if isempty(elem)
                res = false;
            else
                res = ccvd.removeFilter(1, elem);
            end
        end
    end
end

%% ------------------------------------------------------------------------
function fileObj = getFileObj(obj)
    if isempty(obj.CodeCovData)
        fileObj = internal.cxxfe.instrum.File.empty;
        return
    end

    codeCovDataImpl = obj.CodeCovData.CodeCovDataImpl;
    files = codeCovDataImpl.CodeTr.getFilesInCurrentModule();
    % The object is supposed to have only 1 file
    if isscalar(files)
        fileObj = files(1);
    else
        fileObj = internal.cxxfe.instrum.File.empty;
    end
end

function nonEmptyResObjArray = removeResultsWithEmptyData(resObjArray)
nonEmptyResObjMask = arrayfun(@isNonEmptyResult,resObjArray);
nonEmptyResObjArray = resObjArray(nonEmptyResObjMask);
end

function bool = isNonEmptyResult(resultObj)
isEmptyFilename = isempty(resultObj.Filename);
isEmptyCreationDate = isempty(resultObj.CreationDate);

% assert that neither Filename or CreationDate are individually empty for a Result object.
assert(isEmptyFilename == isEmptyCreationDate,message("MATLAB:coverage:result:EmptyFilenameOrCreationDate"));

bool = ~(isEmptyFilename || isEmptyCreationDate);
end

%% ------------------------------------------------------------------------
function elem = getFilteredElement(ccvd, uuid, outcomeIdx)
if isempty(outcomeIdx) || (outcomeIdx == 0)
    elem = uuid;
else
    % If we are filtering an outcome, find the coverage point in the
    % code traceability data-model and get the expected outcome.
    obj = ccvd.CodeTr.Model.findElement(uuid);
    if isempty(obj)
        elem = obj;
    elseif isa(obj, 'internal.cxxfe.instrum.CoveragePoint')
        % The true outcome should come first.
        if ((isa(obj, 'internal.cxxfe.instrum.DecisionPoint') && obj.isBoolean) || ...
           isa(obj, 'internal.cxxfe.instrum.ConditionPoint')) && ...
           (obj.outcomes(1).kind == internal.cxxfe.instrum.OutcomeKind.FALSE_OUTCOME)
            outcomeIdx = 3 - outcomeIdx;
        end
        elem = obj.outcomes(outcomeIdx);
    else
        % Special case for a decision corresponding to a C/C++ "case".
        % In that case, we get the outcome's UUID, not the "switch" decision's.
        if outcomeIdx == 1
            elem = obj;
        else
            % Filtering the false outcome of the last case corresponds to
            % filtering the 'default' outcome.
            assert(outcomeIdx == 2);
            allOutcomes = obj.Parent.outcomes;
            defaultOutcome = [];
            for ii = 1:allOutcomes.Size()
                currOutcome = allOutcomes(ii);
                if ismember(currOutcome.getSourceCode(), {'default:', '}'})
                    defaultOutcome = currOutcome;
                elseif isequal(allOutcomes(ii), obj)
                    if ii == allOutcomes.Size()
                        assert(~isempty(defaultOutcome));
                        elem = defaultOutcome;
                        break
                    else
                        assert((ii + 1) == allOutcomes.Size());
                        elem = allOutcomes(ii + 1);
                        break
                    end
                end
            end
        end
    end
end
end

% LocalWords:  codeinstrum codecov
