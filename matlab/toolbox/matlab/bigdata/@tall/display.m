function display(obj, name) %#ok<DISPLAY> showing extra information.
%DISPLAY Display tall array.

% Copyright 2015-2017 The MathWorks, Inc.

if nargin < 2
    name = inputname(1);
elseif ~isempty(name)
    validateattributes(name, {'char','string'}, {'row'}, mfilename, 'name', 2);
end

if ~obj.ValueImpl.IsValid
    iPrintInvalidDisplay(name);
    return;
end

arrayInfo = matlab.bigdata.internal.util.getArrayInfo(obj);

if ~isempty(arrayInfo.Error)
    err = arrayInfo.Error;
    if isempty(name)
        warning(message('MATLAB:bigdata:array:DisplayPreviewErroredNoName', err.message));
    else
        warning(message('MATLAB:bigdata:array:DisplayPreviewErrored', name, err.message));
    end
end
context = matlab.bigdata.internal.util.DisplayInfo(name, arrayInfo);
displayImpl(obj.Adaptor, context, obj.ValueImpl);
end

% Print an invalid array display for cases where the underlying data is no
% longer valid, for example when the execution environment has been closed.
function iPrintInvalidDisplay(name)

if isequal(matlab.internal.display.formatSpacing(), 'compact')
    sep = newline;
else
    sep = [newline newline];
    fprintf('\n');
end

if ~isempty(name)
    fprintf('%s =%s', name, sep);
end

fprintf('    %s%s', getString(message('MATLAB:bigdata:array:InvalidTall')), sep);
end
