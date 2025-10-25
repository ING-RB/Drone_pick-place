function [method,winsz,nanflag,samplePoints,sgdeg,dim,dvars,replace] = parseSmoothdataInputs(A, is2D, varargin)
    %parseSmoothdataInputs Parse inputs for smoothdata and smoothdata2
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2023 The MathWorks, Inc.
    
    method = "movmean";
    smoothingFactor = 0.25;
    dvars = [];
    winsz = [];
    sgdeg = 2;
    nanflag = "omitnan";
    currentErrorTerm = "Method";
    
    charHelper = @(x) (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x));
    numArgs = nargin - 1;
    argIdx = 1;
    
    % Check for dim argument - skipped for the 2D case
    if ~is2D && (argIdx < numArgs) && ~charHelper(varargin{1})
        if istabular(A)
            error(message("MATLAB:smoothdata:noDimForTable"));
        end
        dim = varargin{argIdx};
        if ~(isnumeric(dim) || islogical(dim)) || ~isscalar(dim) || ...
                ~isreal(dim) || ((dim < 1) || (dim ~= round(dim)))
            error(message("MATLAB:getdimarg:dimensionMustBePositiveInteger"));
        end
        argIdx = 2;
    else
        if ~is2D && istabular(A)
            dim = 1;
            dvars = 1:size(A,2);
        else
            dim = matlab.internal.math.firstNonSingletonDim(A);
        end
    end
    
    if is2D
        methodNames = ["movmean", "movmedian", "gaussian", "lowess", "loess",...
            "sgolay"];
        methodErrorID = "MATLAB:smoothdata2:invalidMethod";
    else
        methodNames = ["movmean", "movmedian", "gaussian", "lowess", "loess",...
            "rlowess", "rloess", "sgolay"];
        methodErrorID = "MATLAB:smoothdata:invalidMethod";
    end
    userGaveMethod = false;
    % Method and window size parsing
    if argIdx < numArgs
        if charHelper(varargin{argIdx})
            methodID = partialMatch(methodNames, varargin{argIdx});
            if nnz(methodID) > 1
                error(message(methodErrorID));
            elseif nnz(methodID) == 1
                method = methodNames(methodID);
                userGaveMethod = true;
                argIdx = argIdx + 1;
                currentErrorTerm = "Winsize";
                % Window size parsing
                if (argIdx < numArgs) && ( isnumeric(varargin{argIdx}) || ...
                            islogical(varargin{argIdx}) || ...
                            isdatetime(varargin{argIdx}) || ...
                            isduration(varargin{argIdx}) || ...
                            (is2D && iscell(varargin{argIdx})) )
                    if is2D
                        winsz = varargin{argIdx};
                        matlab.internal.math.validate2DWindow(winsz);
                    else
                        winsz = checkWindowSize(varargin{argIdx});
                    end
                    argIdx = argIdx + 1;
                    currentErrorTerm = "Nanflag";
                end
            end
        else
            error(message(methodErrorID));
        end
    end
    
    % Set error ID for Name-Value pair errors
    NVPairID = "NVPair";
    if ~is2D && istabular(A)
        NVPairID = NVPairID + "Table";
    end
    if method == "sgolay"
        NVPairID = NVPairID + "SGolay";
    end
    
    % 'omitnan' / 'includenan' parsing
    userGaveNaNCondition = false;
    if (argIdx < numArgs) && charHelper(varargin{argIdx})
        nanflagID = partialMatch(["omitnan", "includenan", "omitmissing","includemissing"],...
            varargin{argIdx});
        if any(nanflagID)
            currentErrorTerm = NVPairID;
            if nanflagID(2) || nanflagID(4)
                nanflag = "includenan";
            end
            userGaveNaNCondition = true;
            argIdx = argIdx + 1;
        end
    end
    
    if ~is2D && istimetable(A)
        samplePoints = matlab.internal.math.checkSamplePoints(A.Properties.RowTimes,A,false,true,1);
    else
        samplePoints = [];
    end
    
    validParams = ["SamplePoints", "SmoothingFactor"];
    if is2D
        allParams = [validParams, "Degree"];
    else
        allParams = [validParams, "DataVariables", "ReplaceValues" "Degree"];
    end
    if ~is2D && istabular(A)
        validParams(end+1) = "DataVariables";
        validParams(end+1) = "ReplaceValues";
    end
    if method == "sgolay"
        validParams(end+1) = "Degree";
    end
    
    % Name-Value pair parsing
    userGaveDegree = false;
    spvar = [];
    replace = true;
    while argIdx < numArgs
        if ~charHelper(varargin{argIdx})
            throwInvalidInputError(currentErrorTerm,is2D);
        else
            if currentErrorTerm == "Winsize"
                currentErrorTerm = "Nanflag";
            end
        end
        if ~userGaveMethod && any(partialMatch(methodNames, varargin{argIdx}))
            error(message("MATLAB:smoothdata:methodAfterOptions"));
        elseif any(partialMatch(["omitnan", "includenan","omitmissing","includemissing"], varargin{argIdx}))
            if userGaveNaNCondition
                error(message("MATLAB:smoothdata:duplicateNanflag"));
            else
                error(message("MATLAB:smoothdata:nanflagAfterOptions"));
            end
        elseif nnz(partialMatch(allParams, varargin{argIdx})) > 1
            % Case where user specifies "D" as the name
            throwInvalidInputError(currentErrorTerm,is2D);
        elseif ~(nnz(partialMatch(validParams, varargin{argIdx})) == 1)
            if ~is2D && partialMatch("DataVariables", varargin{argIdx}, 2) && ~istabular(A)
                error(message("MATLAB:smoothdata:DataVariablesArray"));
            elseif ~is2D && partialMatch("ReplaceValues", varargin{argIdx}, 2) && ~istabular(A)
                error(message("MATLAB:smoothdata:ReplaceValuesArray"));
            elseif partialMatch("Degree", varargin{argIdx}, 2) && (method ~= "sgolay")
                error(message("MATLAB:smoothdata:degreeNoSgolay"));
            else
                % Error message might be about invalid method, option, or
                % Name-Value pair depending on the input arguments
                throwInvalidInputError(currentErrorTerm,is2D);
            end
        elseif partialMatch("SamplePoints", varargin{argIdx}, 2)
            currentErrorTerm = NVPairID;
            argIdx = argIdx + 1;
            if argIdx >= numArgs
                error(message("MATLAB:smoothdata:nameNoValue", 'SamplePoints'));
            else
                if ~is2D && istimetable(A)
                    error(message("MATLAB:samplePoints:SamplePointsTimeTable"));
                end
                samplePoints = varargin{argIdx};
                if is2D
                    if isempty(winsz)
                        matlab.internal.math.validate2DSamplePoints(A, samplePoints);
                    else
                        matlab.internal.math.validate2DSamplePoints(A, samplePoints, winsz);
                    end
                    if ~startsWith(method,["m","g"]) && (isdatetime(samplePoints{1}) || isduration(samplePoints{1})) && ...
                        ~(isdatetime(samplePoints{2}) || isduration(samplePoints{2}))
                        error(message("MATLAB:smoothdata2:invalidSPTypeLocalReg"));
                    end
                else
                    AisTable = istabular(A);
                    [samplePoints,spvar] = matlab.internal.math.checkSamplePoints(samplePoints,A,AisTable,false,dim);
                end
            end
        elseif partialMatch("SmoothingFactor", varargin{argIdx}, 2)
            currentErrorTerm = NVPairID;
            if ~isempty(winsz)
                error(message("MATLAB:smoothdata:tuneAndWindow"));
            end
            argIdx = argIdx + 1;
            if argIdx >= numArgs
                error(message("MATLAB:smoothdata:nameNoValue", 'SmoothingFactor'));
            else
                smoothingFactor = checkSmoothingFactor(varargin{argIdx});
            end
        elseif ~is2D && partialMatch("DataVariables", varargin{argIdx})
            currentErrorTerm = NVPairID;
            argIdx = argIdx + 1;
            if argIdx >= numArgs
                error(message("MATLAB:smoothdata:nameNoValue", 'DataVariables'));
            else
                dvars = matlab.internal.math.checkDataVariables(A, ...
                    varargin{argIdx}, 'smoothdata');
            end
        elseif ~is2D && partialMatch("ReplaceValues",varargin{argIdx})
            currentErrorTerm = NVPairID;
            argIdx = argIdx + 1;
            if argIdx >= numArgs
                error(message("MATLAB:smoothdata:nameNoValue",'ReplaceValues'));
            end
            replace = matlab.internal.datatypes.validateLogical(varargin{argIdx},'ReplaceValues');
        else
            % 'Degree' Name-Value pair
            argIdx = argIdx + 1;
            currentErrorTerm = NVPairID;
            if argIdx >= numArgs
                error(message("MATLAB:smoothdata:nameNoValue", 'Degree'));
            else
                sgdeg = varargin{argIdx};
            end
            userGaveDegree = true;
        end
        argIdx = argIdx + 1;
    end
    if  ~is2D && ~isempty(spvar)
        dvars(dvars == spvar) = []; % remove sample points var from data vars
    end
    
    % Check the data variables:
    if  ~is2D && istabular(A)
        dvarsValid = varfun(@validDataVariableType, A, 'InputVariables',...
            dvars, 'OutputFormat', 'uniform');
        if ~all(dvarsValid)
            % Check if any variables are complex integers:
            if any(varfun(@(x) isinteger(x) && ~isreal(x), A, 'InputVariables', ...
                    dvars, 'OutputFormat', 'uniform'))
                error(message("MATLAB:smoothdata:complexIntegers"));
            end
            error(message("MATLAB:smoothdata:nonNumericTableVar"));
        end
    end
    
    % Check the type matching for sample points
    if is2D
        if isempty(samplePoints)
            spCell = {[],[]};
        else
            spCell = samplePoints;
        end
        if iscell(winsz)
            checkWindowAndSamplePointsTypes(spCell{1},winsz{1});
            checkWindowAndSamplePointsTypes(spCell{2},winsz{2});
        else
            checkWindowAndSamplePointsTypes(spCell{1},winsz);
            checkWindowAndSamplePointsTypes(spCell{2},winsz);
        end
    else
        checkWindowAndSamplePointsTypes(samplePoints,winsz);
    end
    
    
    autoPickedSize = isempty(winsz);
    nonEmptyInput = ~isempty(A) && ~(istabular(A) && isempty(dvars));
    
    if autoPickedSize && nonEmptyInput
        if is2D
            if isempty(samplePoints)
                samplePoints2D = {[],[]};
            else
                samplePoints2D = samplePoints;
            end
            [xSize,ySize] = size(A);
            if xSize == 1
                % Use 1D window size for vector data
                winszX = 1;
                winszY = matlab.internal.math.chooseWindowSize(A, 2, samplePoints2D{2}, ...
                1-smoothingFactor, dvars);
            elseif ySize == 1
                % Use 1D window size for vector data
                winszX = matlab.internal.math.chooseWindowSize(A, 1, samplePoints2D{1}, ...
                1-smoothingFactor, dvars);
                winszY = 1;
            else
                winszX = matlab.internal.math.chooseWindowSize(A, 1, samplePoints2D{1}, ...
                1-sqrt(smoothingFactor), dvars);
                winszY = matlab.internal.math.chooseWindowSize(A, 2, samplePoints2D{2}, ...
                1-sqrt(smoothingFactor), dvars);
            end
            winsz = {winszX,winszY};
        else
            winsz = matlab.internal.math.chooseWindowSize(A, dim, samplePoints, ...
                1-smoothingFactor, dvars);
        end
    end
    
    % Check the Degree parameter
    if nonEmptyInput
        sgdeg = checkDegree(method, sgdeg, samplePoints, winsz, autoPickedSize, ...
            userGaveDegree, is2D);
    end
    
    end
    
    %--------------------------------------------------------------------------
    function winsz = checkWindowSize(winsz)
    % Check the window size input parameter - 1D case only
    if ~(isvector(winsz) || isempty(winsz)) || ...
            ~(isnumeric(winsz) || isduration(winsz) || islogical(winsz)) || ...
            (numel(winsz) > 2)
        error(message("MATLAB:smoothdata:invalidWinsize"));
    end
    if isfloat(winsz)
        if ~isreal(winsz)
            error(message("MATLAB:smoothdata:noComplexWindows"));
        end
        if issparse(winsz)
            winsz = full(winsz);
        end
    end
    if (isfloat(winsz) || isduration(winsz)) && ~allfinite(winsz)
        error(message("MATLAB:smoothdata:needsFiniteWindows"));
    end
    if any(winsz < 0) || (isscalar(winsz) && winsz == 0)
        error(message("MATLAB:smoothdata:invalidWinsize"));
    end
    end
    
    %--------------------------------------------------------------------------
    function smFactor = checkSmoothingFactor(smFactor)
    % Check the tuning factor input
    
    if isfloat(smFactor)
        if ~isreal(smFactor)
            error(message("MATLAB:smoothdata:noComplex", '''SmoothingFactor'''));
        end
        if issparse(smFactor)
            smFactor = full(smFactor);
        end
    end
    if ~isscalar(smFactor) || ~((isnumeric(smFactor) && ...
            (smFactor >= 0) && (smFactor <= 1)) || islogical(smFactor))
        error(message("MATLAB:smoothdata:invalidSmoothingFactor"));
    end
    
    end
    
    %--------------------------------------------------------------------------
    function sgdeg = checkDegree(method, sgdeg, t, winsz, autoSize, gaveDegree, is2D)
    % Check the Savitzky-Golay degree
    
    % Additional checks for Savitzky-Golay
    if method ~= "sgolay"
        return;
    end
    
    if isfloat(sgdeg)
        if ~isreal(sgdeg)
            error(message("MATLAB:smoothdata:noComplex", '''Degree'''));
        end
        if ~isfinite(sgdeg)
            error(message("MATLAB:smoothdata:needsFinites", '''Degree'''));
        end
    end
    if ~isscalar(sgdeg) || ~isnumeric(sgdeg) || ...
            (fix(sgdeg) ~= sgdeg) || (sgdeg < 0)
        error(message("MATLAB:smoothdata:negativeDegree"));
    end
    sgdeg = full(double(sgdeg));
    
    if is2D
        % Futher degree checks are not performed for the 2D case
        return
    end
    
    % Non-uniform data or time-stamped data
    if ~isempty(t)
        wl = maxWindowLength(t, winsz);
        if (sgdeg >= wl)
            if autoSize
                % Cap the maximum degree, warn if degree was specified
                sgdeg = wl-1;
                if gaveDegree
                    warning(message('MATLAB:smoothdata:degreeAutoClash',...
                        wl, sgdeg));
                end
            else
                if gaveDegree
                    error(message("MATLAB:smoothdata:degreeTooLarge", wl));
                else
                    sgdeg = wl-1;
                end
            end
        end
    else
        % User specified window with [kb kf] syntax
        if ~isscalar(winsz)
            winsz = sum(winsz) + 1;
        end
        if (sgdeg >= winsz)
            if autoSize
                % Cap the maximum degree, warn if degree was specified
                sgdeg = fix(winsz-1);
                if gaveDegree
                    warning(message("MATLAB:smoothdata:degreeAutoClash",...
                        winsz, sgdeg));
                end
            else
                if gaveDegree
                    error(message("MATLAB:smoothdata:degreeTooLarge",...
                        winsz));
                else
                    sgdeg = fix(winsz-1);
                end
            end
        end
    end
    end
    
    %--------------------------------------------------------------------------
    function wl = maxWindowLength(t, winsz)
    % Compute the maximum window length of non-uniform data
        wl = max(movsum(ones(1, numel(t)), winsz, 'SamplePoints', t));
    end
    
    %--------------------------------------------------------------------------
    function tf = partialMatch(strChoices, strInput, minLength)
    % Case-insensitive partial matching for option strings
        if ~isstring(strInput)
            strInput = string(strInput);
        end
        if nargin < 3
            minLength = 1;
        end
        if strlength(strInput) < minLength
            tf = false(size(strChoices));
        else
            tf = startsWith(strChoices, strInput, 'IgnoreCase', true);
        end
    end
    
    %--------------------------------------------------------------------------
    function tf = validDataVariableType(x)
    % Indicates valid data types for table variables
        tf = (isnumeric(x) || islogical(x)) && ~(isinteger(x) && ~isreal(x));
    end

    %--------------------------------------------------------------------------
    function checkWindowAndSamplePointsTypes(samplePoints,winsz)
    % Checks that the types of the window size and the sample points are
    % compatible
    samplePointsAreTimeBased = (isdatetime(samplePoints) || isduration(samplePoints));
    if samplePointsAreTimeBased
        % Non-uniform data that is timestamped
        if ~isempty(winsz) && ~isduration(winsz)
            error(message("MATLAB:smoothdata:winsizeNotDuration", class(samplePoints)));
        end
    else
        % Non timestamped data
        if ~isempty(winsz) && isduration(winsz)
            error(message("MATLAB:smoothdata:winsizeIsDuration"));
        end
    end
    end

    %--------------------------------------------------------------------------
    function throwInvalidInputError(currentErrorTerm,is2D)
    if is2D && startsWith(currentErrorTerm,"M") % "Method" is the only error term that starts with "M"
        error(message("MATLAB:smoothdata2:invalidMethod"));
    else
        error(message("MATLAB:smoothdata:invalid" + currentErrorTerm));
    end
    end