function applyPropertyPairs(this, varargin)
%APPLYPROPERTYPAIRS Apply property pairs to the options object

%  Copyright 1986-2007 The MathWorks, Inc.

if ~isempty(varargin)
    narg = length(varargin);
    if ~rem(narg,2)
        for ct = 1:(narg/2)
            this.(varargin{2*ct-1}) = varargin{2*ct};
        end
    else
        ctrlMsgUtils.error('Controllib:general:CompletePropertyValuePairs','setoptions')
    end
end