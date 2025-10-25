function varargout = invokeStatelessLogicalElementwise(fcnInfo, varargin)
%INVOKESTATELESSLOGICALELEMENTWISE Invokes error-free stateless logical elementwise function

%   Copyright 2022 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
stack = createInvokeStack(fcnInfo.Name);
markerFrame = matlab.bigdata.internal.InternalStackFrame(stack); %#ok<NASGU>

try
    args = invokeInputCheck(fcnInfo, varargin{:});
    fcn = str2func(fcnInfo.Name);
    % Only treat the logical operators supported by matlab.io.RowFilter as
    % special for potential tabular row-indexing optimization: and, or,
    % not. xor will be added as soon as it is supported.
    isRowFilterSupported = ~isequal(fcn, @xor);

    fcn = matlab.bigdata.internal.FunctionHandle(fcn);
    if isRowFilterSupported
        [varargout{1:max(1, nargout)}] = logicalElementfun(fcn, args{:});
    else
        [varargout{1:max(1, nargout)}] = elementfun(fcn, args{:});
    end
    varargout = cellfun(@(out) invokeOutputInfo(fcnInfo, out, args), varargout, 'UniformOutput', false);
catch E
    matlab.bigdata.internal.throw(E);
end
end


