function [tf, P] = isLocalExtrema(A, fname, varargin)
%ISLOCALEXTREMA Implementation of local extrema search that can be used by
%ISLOCALMAX and ISLOCALMIN.
%
%   [TF,P] = ISLOCALEXTREMA(A,FNAME,...)
%

%   Copyright 2018-2023 The MathWorks, Inc.

% Only the first input can be tall.
tall.checkIsTall(upper(fname), 1, A);
tall.checkNotTall(upper(fname),1,varargin{:});
    
% We have a specific error for timetable. Other unsupported types go
% through the normal type check.
if strcmpi(A.Adaptor.Class, 'timetable')
    error(message('MATLAB:bigdata:isLocalExtrema:TimetableUnsupported'));
end
typesA = {'numeric','logical','table'};
A = tall.validateType(A,fname,typesA,1);

[dim,opts] = iParseInputs(A,varargin{:});
% Maxima or minima search.
opts.IsMaxSearch = contains(fname, "max");
[tf,P] = iFindAndFilterLocalExtrema(A,dim,opts);
% If tabular output was requested, convert now.
if opts.OutputFormat == "tabular"
    if ismember(A.Adaptor.Class, ["table","timetable"])
        % For OutputFormat - tabular, only keep the selected variables.
        dataVars = opts.AllVars(opts.DataVars);
        if numel(dataVars) < numel(opts.AllVars)
            tf = subselectTabularVars(tf,ismember(opts.AllVars, dataVars));
        end
        % Keep format (table/timetable) and all properties of the input A
        % except for VariableUnits and VariableContinuity. (Only tables are
        % supported).
        tf = array2table(tf, "VariableNames", dataVars, ...
            "DimensionNames", getDimensionNames(A.Adaptor));
        tf = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(tf, A);
        tf = subsasgn(tf, substruct('.', 'Properties', '.', 'VariableUnits'), {});
        tf = subsasgn(tf, substruct('.', 'Properties', '.', 'VariableContinuity'), {});
    else
        tf = array2table(tf);
    end
end
end

%--------------------------------------------------------------------------
function [tf,P] = iFindAndFilterLocalExtrema(A,dim,opts)
% Find local extrema using either slicefun or a stencil method.

import matlab.bigdata.internal.util.isGathered

% The primitive used depends on the dimension we are processing  The
% following sets up the following execution branches:
%
% 1) Fill along tall dimension uses a primitive that manages boundary
%    communication between partitions according to the window rules.
% 2) Fill in any other dimension is processed using slicefun

[stencilTF, stencilP] = isLocalStencil(A, opts);
inmemoryFcnToUse = @matlab.internal.math.isLocalExtrema;
[sliceTF, sliceP] = slicefun(@(X,d) inmemoryFcnToUse(X, opts.IsMaxSearch, ...
    d, "MinProminence", opts.MinProminence,...
    "FlatSelection", opts.FlatType, ...
    "ProminenceWindow", opts.ProminenceWindow), A, dim);
% Ensure that the output adaptors are set for the two possible
% execution branches.
[stencilTF, stencilP] = iSetOutputAdaptors(A, stencilTF, stencilP, opts);
[sliceTF, sliceP] = iSetOutputAdaptors(A, sliceTF, sliceP, opts);

[dimIsKnown, dimValue] = isGathered(hGetValueImpl(dim));

if dimIsKnown
    % Dim is known on the client so we can directly select the correct
    % execution branch.
    [tf, P] = iFindLocalExtremaInDim(stencilTF, stencilP, ...
        sliceTF, sliceP, dimValue);
else
    % Dim is unknown, defer conditional selection using an elementfun to
    % pick the correct execution branch.
    
    [tf, P] = elementfun(...
        @iFindLocalExtremaInDim, ...
        stencilTF, stencilP, sliceTF, sliceP, dim);
end

end

%--------------------------------------------------------------------------
function [tf, P] = iFindLocalExtremaInDim(stencilTF, stencilP, sliceTF, ...
    sliceP, dim)
% Selects between the two possible execution branches for islocal*.
if dim == 1
    % Tall Dim => emit the stencilfun result.
    tf = stencilTF;
    P = stencilP;
else
    % Another other dim => emit slicefun result.
    tf = sliceTF;
    P = sliceP;
end
end

%--------------------------------------------------------------------------
function [TF,P] = iSetOutputAdaptors(A, TF, P, opts)
% Sets the output adaptors.
import matlab.bigdata.internal.adaptors.getAdaptorForType;
import matlab.bigdata.internal.adaptors.TableAdaptor;
inputClass = tall.getClass(A);
TF.Adaptor = getAdaptorForType('logical');
TF.Adaptor = copySizeInformation(TF.Adaptor,A.Adaptor);
if inputClass == "table"
    adaptors = cell(1, numel(opts.DataVars));
    for k = 1:numel(opts.DataVars)
        srcAdaptor = A.Adaptor.getVariableAdaptor(opts.DataVars(k));
        adaptors{k} = getAdaptorForType(iGetProminenceClass(srcAdaptor.Class));
        adaptors{k} = copyTallSize(adaptors{k}, srcAdaptor);
        adaptors{k} = setSmallSizes(adaptors{k}, 1);
    end
    P.Adaptor = TableAdaptor(opts.AllVars(opts.DataVars), adaptors, getDimensionNames(A.Adaptor));
    P = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(P, A);
else
    P.Adaptor = getAdaptorForType(iGetProminenceClass(inputClass));
    P.Adaptor = copySizeInformation(P.Adaptor, A.Adaptor);
end
end

%--------------------------------------------------------------------------
function pClass = iGetProminenceClass(aClass)
pClass = aClass;
if startsWith(aClass, 'int')
    pClass = ['u', pClass];
end
end

%--------------------------------------------------------------------------
function [dim, opts] = iParseInputs(A, varargin)
% Parse and check inputs for tall/islocal*.

opts.IsTabular = strcmpi(A.Adaptor.Class, 'table');
opts.FlatType = 'center';
opts.MinProminence = 0;
opts.ProminenceWindow = [];
opts.DataVars = [];
opts.OutputFormat = "logical";
if opts.IsTabular
    dim = tall.createGathered(1);
    opts.AllVars = getVariableNames(A.Adaptor);
    opts.DataVars = opts.AllVars;
else
    % Arrays follow the first non-singleton dim rule.
    dim = findFirstNonSingletonDim(A);
end

if nargin < 3
    error(message('MATLAB:bigdata:isLocalExtrema:ProminenceWindowRequired'));
end

argIdx = 1;

if ~isNonTallScalarString(varargin{1})
    if nargin < 4
        error(message('MATLAB:bigdata:isLocalExtrema:ProminenceWindowRequired'));
    end
    if opts.IsTabular
        error(message('MATLAB:isLocalExtrema:DimensionTable'));
    end
    dim = matlab.internal.math.getdimarg(varargin{argIdx});
    dim = tall.createGathered(dim);
    argIdx = 2;
end

% All in-memory islocalmax/min options.
allOptions = [ "MinProminence", "FlatSelection", "DataVariables", ...
    "ProminenceWindow", "MaxNumExtrema", "MinSeparation", "SamplePoints", ...
    "OutputFormat"];
    
% Parse Name-Value Pairs.
numRemainingArguments = nargin-1-(argIdx-1);
if rem(numRemainingArguments, 2) ~= 0
    error(message('MATLAB:isLocalExtrema:NameValuePairs'));
end
for i = argIdx:2:(nargin-1)
    % Everything is name-value pairs.
    if ~isNonTallScalarString(varargin{i})
        if opts.IsTabular
            error(message('MATLAB:bigdata:isLocalExtrema:InvalidNameTable'));
        else
            error(message('MATLAB:bigdata:isLocalExtrema:InvalidNameArray'));
        end
    end
    optionMatches = iPartialMatchStringChoices(allOptions, varargin{i});
    % Matches "MaxNumExtrema" and "MinProminence"
    if nnz(optionMatches) ~= 1
        if opts.IsTabular
            error(message('MATLAB:bigdata:isLocalExtrema:InvalidNameTable'));
        else
            error(message('MATLAB:bigdata:isLocalExtrema:InvalidNameArray'));
        end
    end
    optionStr = allOptions(optionMatches);
    % Matches for options that aren't supported by tall.
    if optionStr == "MaxNumExtrema"
        error(message('MATLAB:bigdata:isLocalExtrema:MaxNumExtremaUnsupported'));
    elseif optionStr == "MinSeparation"
        error(message('MATLAB:bigdata:isLocalExtrema:MinSeparationUnsupported'));
    elseif optionStr == "SamplePoints"
        error(message('MATLAB:bigdata:isLocalExtrema:SamplePointsUnsupported'));
    end
    % At this point, we have a single match for a valid option.
    if optionStr == "MinProminence"
        opts.MinProminence = varargin{i+1};
        if ~(isnumeric(opts.MinProminence) || islogical(opts.MinProminence)) || ...
           ~iCheckForRealFiniteNonNegativeScalar(opts.MinProminence)
            error(message('MATLAB:isLocalExtrema:MinProminenceInvalid'));
        end
    elseif optionStr == "FlatSelection"
        flatOptions = [ "all", "first", "center", "last"];
        if ~isNonTallScalarString(varargin{i+1})
            error(message('MATLAB:isLocalExtrema:FlatSelectionInvalid'));
        else
            tf = iPartialMatchStringChoices(flatOptions, varargin{i+1});
            if sum(tf) ~= 1 % No or multiple matches.
                error(message('MATLAB:isLocalExtrema:FlatSelectionInvalid'));
            end
            opts.FlatType = flatOptions(tf);
        end
    elseif optionStr == "DataVariables"
        if opts.IsTabular
            varInds = checkDataVariables(A,varargin{i+1},mfilename);
            opts.DataVars = opts.AllVars(sort(varInds));
        else
            error(message('MATLAB:isLocalExtrema:DataVariablesArray'));
        end
    elseif optionStr == "OutputFormat"
        opts.OutputFormat = validatestring(varargin{i+1},["logical","tabular"],'isLocalExtrema','OutputFormat');
    else % ProminenceWindow
        pwin = varargin{i+1};
        if isduration(pwin)
            error(message('MATLAB:isLocalExtrema:ProminenceWindowCannotBeDuration'));
        end
        validPwin = isnumeric(pwin) && isreal(pwin);
        if validPwin
            if isscalar(pwin)
                validPwin = ~isnan(pwin) && (pwin > 0);
            else
                validPwin = all(~isnan(pwin(:))) && all(pwin(:) >= 0) && ...
                    isvector(pwin) && (numel(pwin) == 2);
            end
        end
        if ~validPwin
            error(message('MATLAB:isLocalExtrema:ProminenceWindowLengthInvalid'));
        end
        opts.ProminenceWindow = iSnapWindowToIntegers(pwin);
    end
end
if opts.IsTabular
    % Convert data variables to indices.
    [~,opts.DataVars] = ismember(opts.DataVars, opts.AllVars);
end

% Prominence window must be supplied for tall data.
if isempty(opts.ProminenceWindow)
    error(message('MATLAB:bigdata:isLocalExtrema:ProminenceWindowRequired'));
end

end

%--------------------------------------------------------------------------
function pwin = iSnapWindowToIntegers(pwin)
    if isscalar(pwin)
        if mod(pwin, 2) == 0
            pwin = [pwin/2 pwin/2-1];
        else
            pwin = floor(pwin/2)*ones(1,2);
        end
    else
        pwin = floor(pwin);
    end
end

%--------------------------------------------------------------------------
function tf = iCheckForRealFiniteNonNegativeScalar(A)
% Determine if an input is a real, finite, non-negative scalar.
    tf = isreal(A) && isscalar(A) && (A >= 0) && isfinite(A);
end

%--------------------------------------------------------------------------
function tf = iPartialMatchStringChoices(strChoices, strInput)
% Case-insensitive partial matching for option strings

strInput = convertCharsToStrings(strInput);
if strlength(strInput) < 1
    tf = false(size(strChoices));
else
    tf = startsWith(strChoices, strInput, 'IgnoreCase', true);
end
end
