function S = getFunctionInfo(filterType, blkH, S)
% getFunctionInfo Determine if a named function is a Simulink or MATLAB Fcn
%
%    fcnType = getFunctionType(fcnName, blkH)
%
%   Inputs:
%     filterType - 'EKF' or 'UKF'
%     blkH       - Handle to the caller block
%     S          - Structure
%
%   Outputs:
%     S          - The input structure with added fields about the user
%                  provided functions

%   Copyright 2016-2018 The MathWorks, Inc.

simulinkFunctionCatalog = Simulink.FunctionGraphCatalog(blkH);

% Gather info about the functions
[S.Predict.Fcn, S.Predict.FcnType, S.Predict.FcnIsFound, ...
    S.Predict.FcnNargin, S.Predict.FcnNargout, S.Predict.FcnErrors] = ...
    localGetFunctionInfo(S.Predict.Fcn, simulinkFunctionCatalog);
[S.Correct.Fcn, S.Correct.FcnType, S.Correct.FcnIsFound, ...
    S.Correct.FcnNargin, S.Correct.FcnNargout, S.Correct.FcnErrors] = ...
    localGetFunctionInfo(S.Correct.Fcn, simulinkFunctionCatalog);
if strcmp(filterType,'EKF')
    [S.Predict.JacobianFcn, S.Predict.JacobianFcnType, S.Predict.JacobianFcnIsFound, ...
        S.Predict.JacobianFcnNargin, S.Predict.JacobianFcnNargout, S.Predict.JacobianFcnErrors] = ...
        localGetFunctionInfo(S.Predict.JacobianFcn, simulinkFunctionCatalog);
    [S.Correct.JacobianFcn, S.Correct.JacobianFcnType, S.Correct.JacobianFcnIsFound, ...
        S.Correct.JacobianFcnNargin, S.Correct.JacobianFcnNargout, S.Correct.JacobianFcnErrors] = ...
        localGetFunctionInfo(S.Correct.JacobianFcn, simulinkFunctionCatalog);
end

% Determine block config parameters:
S.Predict.BlockConfig = localGetBlockConfig(S.Predict.Fcn, S.Predict.FcnType,...
    S.Predict.FcnIsFound, S.Predict.ExpectedNargin);
S.Correct.BlockConfig = localGetBlockConfig(S.Correct.Fcn, S.Correct.FcnType,...
    S.Correct.FcnIsFound, S.Correct.ExpectedNargin);
end

function [fcnNames,fcnTypes,fcnIsFound,fcnNargin,fcnNargout,fcnErrors] = ...
    localGetFunctionInfo(fcnNames, simulinkFunctionCatalog)
% localDetermineFcnType Determine if fcns in fcnNames can be located now
%
% Inputs:
%    fcnNames                - Cell array containing fcn names
%    simulinkFunctionCatalog - Catalog of all Simulink Fcns callable from
%                              this block, from Simulink.FunctionGraphCatalog
%
% Outputs:
%    tf - [numel(fcnNames) 1] logical, true if fcn can be located now

% Pre-assign all outputs, in case we return early due to an error
Nf = numel(fcnNames);
fcnTypes = cell(Nf,1);
fcnIsFound = false(Nf,1);
fcnNargin = -2*ones(Nf,1); % -1 is reserved for varargin/varargout MLFcns. -2: error/unset/not determined
fcnNargout = fcnNargin;
fcnErrors = cell(Nf,1);

% Pre-process function names:
% * trim whitespace
% * remove single/double quotes, if necessary
% * check for
% * if first character is @, remove it
for kk=1:Nf
    fcnErrors{kk} = [];
    
    % trim whitespace
    fcnNames{kk} = strtrim(fcnNames{kk});
    % ensure char (not string)
    fcnNames{kk} = char(fcnNames{kk});
    % if the fcn name is enclosed in single or double quotes, remove them
    fcnNameLen = numel(fcnNames{kk});
    if fcnNameLen>2
        if (fcnNames{kk}(1)=='''' && fcnNames{kk}(end)=='''') || ...
                (fcnNames{kk}(1)=='"' && fcnNames{kk}(end)=='"')
            fcnNames{kk} = fcnNames{kk}(2:end-1);
            fcnNameLen = fcnNameLen - 2;
        end
    end
    % check if no name is specified
    if fcnNameLen==0
        fcnErrors{kk} = message('shared_tracking:blocks:errorFcnNotSpecified');
        continue;
    end
    % @ character removal and anonymous fcn check
    if fcnNameLen>0 && fcnNames{kk}(1)=='@'
        if fcnNameLen>1 && fcnNames{kk}(2)=='('
            fcnErrors{kk} = message('shared_tracking:blocks:errorAnonymousFcn',fcnNames{kk});
            continue;
        end
        fcnNames{kk} = fcnNames{kk}(2:end);
        %fcnNameLen = fcnNameLen - 1; % not used, hence skip this operation
    end
end

% Determine types: SimulinkFcn or MATLABFcn. Find Simulink Functions 1st
[isSLFcn,slFcnPosInCatalog] = ismember(fcnNames,{simulinkFunctionCatalog.name});
fcnTypes(isSLFcn) = {'SimulinkFcn'};
% Assume the ones not found are .m MATLAB Fcns
fcnTypes(~isSLFcn) = {'MATLABFcn'};

% Determine if fcn is found
for kk=1:Nf
    % If we already caught an error, no need to go further
    if ~isempty(fcnErrors{kk})
        continue;
    end
    
    if isSLFcn(kk)
        % Is SLFcn in a package? This is not supported as of now
        if contains(fcnNames{kk},'.')
            fcnIsFound(kk) = false();
            fcnErrors{kk} = message('shared_tracking:blocks:errorFcnNotFound',fcnNames{kk});
            continue;
        end
        % Get handle of the SLFcn
        slFcnH = simulinkFunctionCatalog(slFcnPosInCatalog(kk)).handle;
        % Is SLFcn under model reference? If so, slFcnH is just a handle to
        % the ModelReference block. Load the referenced model, get the
        % actual handle to the SLFcn in that case.
        if strcmp(get_param(slFcnH,'BlockType'),'ModelReference')
            slFcnH = localGetSLFcnHandleInModelRef(slFcnH, fcnNames{kk});
        end
        % SLFcns are "found" by definition, due to the way fcntype is
        % detected. However, they might have been commented out.
        if localIsNotCommented(slFcnH)
            fcnIsFound(kk) = true();
            % Determine SLFcn nargin and nargout
            %
            % LookUnderMasks and FollowLinks 'on', because SLFcn may be coming form a library
            fcnNargin(kk) = numel(find_system(slFcnH, 'SearchDepth', 1, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'BlockType','ArgIn'));
            fcnNargout(kk) = numel(find_system(slFcnH, 'SearchDepth', 1, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'BlockType','ArgOut'));
        else
            % SLFcn is commented out
            fcnIsFound(kk) = false();
            fcnErrors{kk} = message('shared_tracking:blocks:errorSimulinkFcnCommentedOut',fcnNames{kk});
            continue;
        end
    else
        fcnIsFound(kk) = localIsMATLABFcnFound(fcnNames{kk});
        if ~fcnIsFound(kk)
            fcnErrors{kk} = message('shared_tracking:blocks:errorFcnNotFound',fcnNames{kk});
            continue;
        end
        try
            % nargin/out may fail if file is not a function (a script)
            fcnNargin(kk) = nargin(fcnNames{kk});
            fcnNargout(kk) = nargout(fcnNames{kk});
        catch
            fcnErrors{kk} = message('shared_tracking:blocks:errorNargCheck',fcnNames{kk});
            continue;
        end
    end
end
end

function tf = localIsMATLABFcnFound(fcnName)
% localDetermineFcnTypeHelper Determine if fcnName can be found, and it's a
%                             valid MATLAB Fcn

tf = false();
% Is the file a built-in fcn? If no, ensure it is found and has the right
% extension
if ~exist(fcnName,'builtin')
    S = which(fcnName,'-all');
    if isempty(S)
        return;
    end
    % Check for the right extensions: .p or .m
    hasRightExtension = false();
    for kk=1:numel(S)
        [~,~,ext] = fileparts(S{kk});
        if any(strcmpi(ext,{'.m','.p'}))
            hasRightExtension = true;
            break;
        end
    end
    if ~hasRightExtension
        return;
    end
end

% Passed all the checks, return true
tf = true();
end

function S = localGetBlockConfig(fcnNames, fcnTypes, fcnIsFound, fcnExpectedNargin)

Nf = numel(fcnNames);
isSLFcn = strcmp('SimulinkFcn',fcnTypes);
S.NumberOfInports = -1*ones(Nf,1);

for kk=1:Nf
    if isSLFcn(kk)
        S.NumberOfInports(kk) = 0;
    else
        if fcnIsFound(kk)
            if nargin(fcnNames{kk})>fcnExpectedNargin(kk)
                S.NumberOfInports(kk) = 1;
            else
                S.NumberOfInports(kk) = 0;
            end
        end
    end
end
end

function slFcnH = localGetSLFcnHandleInModelRef(modelRefH, fcnName)
% Simulink.FunctionGraphCatalog return a handle to the ModelReference block
% when the SLFcn is in model ref. Get the handle to the actual SLFcn in
% referenced model.

modelRefH = load_system(get_param(modelRefH,'ModelName'));
refSLFcnH = find_system(modelRefH,...
    'SearchDepth',2,...
    'LookUnderMasks', 'on', ...
    'FollowLinks', 'on', ...    
    'BlockType','TriggerPort',...
    'IsSimulinkFunction','on',...
    'FunctionName',fcnName); % TriggerPort handle underneath the Fcn
% Get the name of TriggerPort's parent (SLFcn itself), then its handle
slFcnH = get_param( get_param(refSLFcnH,'Parent'), 'Handle');
end

function tf = localIsNotCommented(blkH)
tf = true;
modelH = bdroot(blkH);
while tf && blkH~=modelH
   tf = tf && strcmp(get_param(blkH,'Commented'), 'off');
   blkH = get_param(get_param(blkH,'Parent'), 'Handle');
end
end
