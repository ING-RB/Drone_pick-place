function out = enableAdaptorAssertion(tf)
%ENABLEADAPTORASSERTION Enables the assertion that checks that the
%information of a chunk of a tall array matches with the adaptor.
%
%   See also: matlab.bigdata.internal.util.unpackTallArguments

%   Copyright 2022 The MathWorks, Inc.

persistent STATE;

if isempty(STATE)
    % By default, this check is disabled.
    STATE = false;
end

if nargout
    out = STATE;
end

if nargin && ~isempty(tf)
    STATE = logical(tf);
end

end