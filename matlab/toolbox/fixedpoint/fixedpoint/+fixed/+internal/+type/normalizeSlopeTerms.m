function [fixedExpOut,slopeAdjustmentFactor] = normalizeSlopeTerms(fixedExpIn,varargin)
% normalizeSlopeTerms normalize slope terms so 1<=slopeAdjustmentFactor<2
%
% Usage
%   [fixedExpOut,slopeAdjustmentFactor] = ...
%     normalizeSlopeTerms(fixedExpIn,Slope1,Slope2,...)
%
% Finds fixedExpOut and slopeAdjustmentFactor, such solve the eq.
%
%   2^fixedExpOut * slopeAdjustmentFactor = 2^fixedExpIn * Slope1 * Slope2 * ...
%
% care must be taken because the total slope is allowed to exceed the
% finite representable range of doubles, such as
%    2^63000 * 1.5
%
% Input
%    fixedExpIn  integer valued initial fixed exponent
%    Slope1      optional, positive value representing part of Slope
%    Slope2      optional, positive value representing part of Slope
%    ...         optional, positive value representing part of Slope
%
% Outputs
%    fixedExpOut  integer valued initial fixed exponent
%    slopeAdjustmentFactor  double in range 1 <= slopeAdjustmentFactor < 2
%

% Copyright 2017-2020 The MathWorks, Inc.

%#codegen
    %coder.inline('always')
    
    %assert(round(fixedExpIn)==fixedExpIn);
    %assert(isfinite(fixedExpIn));
    
    fixedExpOut = fixedExpIn;
    slopeAdjustmentFactor = 1.0;

    n = nargin - 1;
    for i=1:n
        curSlope = double(varargin{i});
        
        %assert(curSlope>=0);
        %assert(isfinite(curSlope));
        
        if 1.0 ~= curSlope
        
            [f,e]=log2(curSlope);
            f = f * 2;
            e = e - 1;
            fixedExpOut = fixedExpOut + e;
            % The following my push slopeAdjustmentFactor out of
            % normalized ranges, so need a clean up step later
            slopeAdjustmentFactor = slopeAdjustmentFactor * f;
            
            if slopeAdjustmentFactor >= 2
                slopeAdjustmentFactor = slopeAdjustmentFactor * 0.5;
                fixedExpOut = fixedExpOut + 1;
            end
            %assert(1<=slopeAdjustmentFactor);
            %assert(slopeAdjustmentFactor < 2);
        end
    end
end
