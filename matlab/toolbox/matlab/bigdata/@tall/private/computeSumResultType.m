function outAdaptor = computeSumResultType(in, precisionFlagCell, methodName)
%computeSumResultType compute the output adaptor for the result of SUM
%   outAdaptor = computeSumResultType(in, precisionFlagCell)
%   in is the input tall array or table
%   precisionFlagCell is {'default'} or {} or similar
%   outAdaptor gives the (unsized) adaptor to use for the output

% Copyright 2016-2022 The MathWorks, Inc.

% If we hit a table then loop over the variables.
if istabular(in)
    outAdaptor = determineAdaptorForTabularMath( ...
        @(x) computeSumResultType(x, precisionFlagCell, methodName), methodName, in);
else
    outAdaptor = getOutputAdaptor(in.Adaptor, precisionFlagCell);
end
end


function outAdaptor = getOutputAdaptor(inAdaptor, precisionFlagCell)
inClz = inAdaptor.Class;
if strcmp(inClz, 'duration') || isequal(precisionFlagCell, {'native'})
    % durations are always the same as 'native'
    outClz = inClz;
elseif isequal(precisionFlagCell, {'double'})
    outClz = 'double';
elseif isequal(precisionFlagCell, {'default'})
    % 'default' generally means 'double', unless the input is 'single'. However, if
    % inType isn't known, it *might* be single, so we can't specify the output
    % in that case.
    if strcmp(inClz, 'single')
        outClz = inClz;
    elseif ~isempty(inClz)
        % The type is known not to be single - so 'default' means 'double'
        outClz = 'double';
    else
        % Fall-back - inType might be single
        outClz = '';
    end
else
    % Not known what the type is going to be
    outClz = '';
end
outAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType(outClz);
end
