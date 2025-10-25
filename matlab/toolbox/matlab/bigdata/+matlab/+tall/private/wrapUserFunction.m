function wrappedfcn = wrapUserFunction(fcn, options, useLikeParameters)
% Wrap a function handle from the user in something that will guard against
% incorrect size and type outputs.
%
% Syntax:
%  wrappedfcn = wrapUserFunction(fcn, options, true) Wraps a user function
%  such that all outputs are compared against a like parameter input. The
%  signature of the wrapper function is:
%
%    function [out1,..,outN] = wrappedfcn(in1,..,inM,like1,..,likeN)
%
%  wrappedfcn = wrapUserFunction(fcn, options, false) Wraps a user function
%  such that all outputs are compared against the input. The signature of
%  the wrapper function is:
%
%    function [out1,..,outM] = wrappedfcn(in1,..,inM)
%

%   Copyright 2018-2023 The MathWorks, Inc.

fcnStruct = functions(fcn);
[~, fcnFilename] = fileparts(fcnStruct.file);

wrappedfcn = @(varargin) iInvokeUserFunction(fcn, fcnFilename, options, useLikeParameters, varargin{:});
wrappedfcn = matlab.bigdata.internal.util.StatefulFunction(wrappedfcn, []);
wrappedfcn = matlab.bigdata.internal.FunctionHandle(wrappedfcn);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [outputTemplates, varargout] = iInvokeUserFunction(fcn, fcnFilename, options, useLikeParameters, outputTemplates, varargin)
% Per-block implementation of wrapUserFunction.
import matlab.bigdata.internal.util.indexSlices;

numOutputs = nargout - 1;
if useLikeParameters
    likeParameters = varargin(end - numOutputs + 1:end);
    varargin(end - numOutputs + 1:end) = [];
else
    assert(numOutputs == numel(varargin), ...
        'Assertion failed: Different number of outputs to inputs when like not used');
    % If we are not using like parameters directly, the output must be the
    % same type and size as the inputs. This is initialized on the first
    % block and held for the partition.
    if isempty(outputTemplates)
        outputTemplates = cell(1, numOutputs);
        for ii = 1:numOutputs
            outputTemplates{ii} = indexSlices(varargin{ii}, []);
        end
    end
end

try
    [varargout{1 : numOutputs}] = fcn(varargin{:});
catch err
    % If the function handle itself has failed to deserialize, we might
    % need to edit the error to ensure auto-attach receives the correct
    % name to attach.
    err = iTranslateIfUnknownFcn(err, fcn, fcnFilename);

    % We need to ensure the error contains the user's function. We must
    % explicitly add this whenever the user's function does throwAsCaller.
    if isempty(err.stack) || strcmp(err.stack(1).name, "iInvokeUserFunction")
        err = matlab.bigdata.BigDataException.build(err);
        err = prependToMessage(err, getString(message('MATLAB:bigdata:custom:ApplyErrorPrepend', char(fcn))));
    end
    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
end

try
    % If we are using like parameters, we need to build output templates
    % now we have at some outputs to derive small sizes. This is
    % initialized on the first block and held for the partition.
    if useLikeParameters && isempty(outputTemplates)
        outputTemplates = cell(1, numOutputs);
        for ii = 1:numOutputs
            likeParameters{ii} = indexSlices(likeParameters{ii}, []);
            outputTemplates{ii} = iMatchSmallSizes(...
                likeParameters{ii}, indexSlices(varargout{ii}, []));
        end
    end
    
    tallSize = size(varargout{1},1);
    for ii = 1:numOutputs
        % Check type and small size match expectation.
        checkOutputBlock(varargout{ii}, outputTemplates{ii}, ii, options.IsDefaultOutputsLike);
        
        % Check tall size is the same for all outputs.
        if size(varargout{ii}, 1) ~= tallSize
            matlab.bigdata.internal.throw(...
                message('MATLAB:bigdata:custom:OutputHeightMismatch', ...
                ii, size(varargout{ii}, 1), ...
                1, tallSize));
        end
    end
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    err = prependToMessage(err, getString(message('MATLAB:bigdata:custom:ApplyErrorPrepend', char(fcn))));
    matlab.bigdata.internal.throw(err);
end
end

function outputsLikeArg = iMatchSmallSizes(outputsLikeArg, actualEmpty)
% Assuming outputsLikeArg has height zero, reshape it to match the small
% sizes of actualEmpty.
if istable(outputsLikeArg) || istimetable(outputsLikeArg)
    if ~istable(actualEmpty) || ~istimetable(actualEmpty) || (width(outputsLikeArg) ~= width(actualEmpty))
        % This will lead to a mismatch type/size error. We do nothing here
        % as checkOutputBlock will issue a descriptive error later on.
        return;
    end
    for ii = 1:width(outputsLikeArg)
        outputsLikeArg.(ii) = iMatchSmallSizes(outputsLikeArg.(ii), actualEmpty.(ii));
    end
else
    outputsLikeArg = reshape(outputsLikeArg, size(actualEmpty));
end
end

function err = iTranslateIfUnknownFcn(err, fcn, fcnFilename)
% Add more information if an error is a "MATLAB:UndefinedFunction" and the
% function handle itself doesn't have enough information to describe what
% was missing properly.
if err.identifier == "MATLAB:UndefinedFunction" ...
        && functions(fcn).function == "UNKNOWN Function" ...
        && ~isempty(fcnFilename)
    msg = message("MATLAB:parallel:serialization:UndefinedFunctionHandleMissingFileText", fcnFilename);
    err = MException("MATLAB:UndefinedFunction", msg);
end
end
