function [B,I,OL,LThresh,UThresh,C] = rmMissingOutliers(funName,A,varargin)
% rmMissingOutliers Helper function for rmmissing and rmoutliers
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   B - A after removing rows or columns
%   I - Colum(row) logical vector indicating removed rows(columns)
%   OL - Logical array indicating detected outliers (only for rmoutliers)
%   LThresh - Lower threshold (only for rmoutliers)
%   UThresh - Upper threshold (only for rmoutliers)
%   C - Center value (only for rmoutliers)
%

%   Copyright 2015-2024 The MathWorks, Inc.

opts = parseInputs(funName,A,varargin{:});
returnAll = nargout > 2;

if ~opts.AisTable
    if ~ismatrix(A)
        issueError(funName,'NDArrays');
    end
    if returnAll
        [I,LThresh,UThresh,C] = applyFun(funName,A,opts);
        OL = I;
    else
        I = applyFun(funName,A,opts);
    end
    I = computeIndex(I,opts.byRows,opts.minNum);
else
    if ~all(varfun(@ismatrix,A,'OutputFormat','uniform'))
        issueError(funName,'NDArrays');
    end
    if opts.byRows
        if opts.dataVarsProvided
            if returnAll
                [I,LThresh,UThresh,C] = applyFun(funName,A(:,opts.dataVars),opts);
                if opts.locsProvided
                    OL = I;
                else
                    OL = false(size(A));
                    OL(:,opts.dataVars) = I;
                end
            else
                I = applyFun(funName,A(:,opts.dataVars),opts);
            end
            if opts.locsProvided && ~istabular(opts.outlierLocs) && ...
                    size(opts.outlierLocs,2) > numel(opts.dataVars)
                % Indexing into tabular outlierLocs was done in the input parsing
                % For non-tabular outlierlocs, only index when a subset of
                % dataVars are selected.
                I = I(:,opts.dataVars);
            end
        else
            % Don't index into a table if we don't have to
            if returnAll
                [I,LThresh,UThresh,C] = applyFun(funName,A,opts);
                OL = I;
            else
                I = applyFun(funName,A,opts);
            end
        end
        I = computeIndex(I,opts.byRows,opts.minNum);
        if istimetable(A) && isequal(funName,'rmmissing')
            % Also remove the rows which correspond to missing RowTimes
            I = I | ismissing(A.Properties.RowTimes);
        end
    else
        if opts.dataVarsProvided
            I = false(1,width(A));
            if returnAll
                [dataVarsI,LThresh,UThresh,C] = applyFun(funName,A(:,opts.dataVars),opts);
                if opts.locsProvided
                    OL = dataVarsI;
                    dataVarsI = dataVarsI(:,opts.dataVars);
                else
                    OL = false(size(A));
                    OL(:,opts.dataVars) = dataVarsI;
                end
            else
                dataVarsI = applyFun(funName,A(:,opts.dataVars),opts);
            end
            dataVarsI = computeIndex(dataVarsI,opts.byRows,opts.minNum);
            I(opts.dataVars) = dataVarsI;
        else
            % Don't index into a table if we don't have to
            if returnAll
                [I,LThresh,UThresh,C] = applyFun(funName,A,opts);
                OL = I;
            else
                I = applyFun(funName,A,opts);
            end
            I = computeIndex(I,opts.byRows,opts.minNum);
        end
    end
end
if opts.AisTable && istabular(I)
    % I only has logical variables here
    I = I.Variables;
end
if any(I)
    B = reduceSize(A,I,opts.byRows);
else
    B = A;
end
end

%--------------------------------------------------------------------------
function [I,L,U,C] = applyFun(funName,A,opts)
% Find missing data or outliers
if isequal(funName,'rmmissing')
    if opts.locsProvided
        I = opts.outlierLocs;
    else
        I = ismissing(A);
    end
else
     if opts.locsProvided
        matlab.internal.math.parseIsOutlierInput(A,1,opts.isoutlierArgs);
        I = opts.outlierLocs;
        if nargout > 1
            Asiz = size(A);
            if opts.AisTable
                if height(A) == 0
                    % grow table so that defaultarrayLike returns NaN rather
                    % than empty variables
                    A = matlab.internal.datatypes.lengthenVar(A,1);
                end
                L = matlab.internal.datatypes.defaultarrayLike([1 width(A)],"like",A);
            else
                L = NaN([1 Asiz(2:end)],"like",A);
            end
            U = L;
            C = L;
        end
     else
         [method, wl, dim, p, sp, vars, maxoutliers, lowup, fmt] = matlab.internal.math.parseIsOutlierInput(A,1,opts.isoutlierArgs);
         if nargout > 1
             [I,L,U,C] =  matlab.internal.math.isoutlierInternal(A, method, wl, dim, p, sp, vars, maxoutliers, lowup, fmt);
         else
             I =  matlab.internal.math.isoutlierInternal(A,method, wl, dim, p, sp, vars, maxoutliers, lowup, fmt);
         end
     end
end
end

%--------------------------------------------------------------------------
function I = computeIndex(I,byRows,minNum)
% Colum(row) logical vector indicating removed rows(columns)
I = sum(I,1 + byRows) >= minNum;
end

%--------------------------------------------------------------------------
function B = reduceSize(A,I,byRows)
% Keep non-missing
if byRows
    B = A(~I,:);
else
    B = A(:,~I);
end
end

%--------------------------------------------------------------------------
function opts = parseInputs(funName,A,varargin)
% Parse RMMISSING/RMOUTLIERS inputs

% We let the ISMISSING/ISOUTLIER calls error out for A of invalid type
opts.AisTable = istabular(A);

% Defaults
opts.minNum = 1;
opts.byRows = true;
opts.dataVarsProvided = false;
if ~opts.AisTable
    if isrow(A) && ~isscalar(A)
        opts.byRows = false;
    end
    opts.dataVars = NaN; % not supported for arrays
else
    opts.dataVars = 1:width(A);
end
doOutliers = isequal(funName,'rmoutliers');
opts.isoutlierArgs = {}; 
opts.locsProvided = false;

% Parse the outlier method, the trailing DIM and N-V pairs (including
% inputs which need to be forwarded to ISOUTLIER).
errorForDataVars = true;
if ~isempty(varargin)
    opts = matlab.internal.math.rmMissingOutliersVarargin(funName,A,opts,...
        errorForDataVars,varargin{:});
end
if doOutliers && opts.locsProvided && opts.AisTable
    for k = opts.dataVars
        vark = A.(k);
        if ~isreal(vark) || ~isfloat(vark) || ~(isempty(vark) || iscolumn(vark))
            error(message('MATLAB:rmoutliers:TableVarInvalid'));
        end
    end
end
end

%--------------------------------------------------------------------------
function issueError(funName,errorId)
% Issue error from the correct error message catalog
error(message(['MATLAB:', funName, ':', errorId]));
end
