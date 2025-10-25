function zf = tfilt(a,b,c,d,z,causal)
%TFILT Filter signal data
%
%    zf = tfilt(a,b,c,d,z,[causal])
%
%    Inputs:
%      a,b,c,d - Filter coefficients in State-Space form. Typically
%                computed from ctrluis.toolstrip.dataprocessing.butter
%      z       - nxy matrix of signal data, columns represent different
%                signal channels
%      causal  - optional logical flag indicating whether causal filtering is
%                used or not. If omitted default true is used. If false
%                noncausal, zero-phase shift, filtering is used.
%
%    Outputs:
%      zf - nxy matrix of filters signal data, columns represent different
%           signal channels
%
%    See also ctrluis.toolstrip.dataprocessing.butter
%

%   Copyright 2013-2020 The MathWorks, Inc.

if nargin < 6
    causal = true;
end

nyu = size(z,2);
if causal
    zf = zeros(size(z));
    for k=1:nyu
        if ~isempty(a)
            x=ltitr(a,b,z(:,k));
            zf(:,k)=x*c'+d*z(:,k);
        else
            zf(:,k) = d*z(:,k);
        end
    end
else
    n  = size(a,1);
    zi = (eye(n)-a)\b;   % Filter at steady state
    zf = zeros(size(z));
    nf = 3*n;            % length of edge transients
    l  = size(z,1);      % Signal length
    for k = 1:nyu
        x = z(:,k);
        y = [2*x(1)-x(nf+1:-1:2);x; 2*x(l)-x(l-1:-1:l-nf)];
        
        % Filter, reverse data, filter, and reverse data
        ys = ltitr(a,b,y,zi*y(1));
        y  = ys*c'+d*y;
        y  = y(length(y):-1:1);
        ys = ltitr(a,b,y,zi*y(1));
        y  = ys*c'+d*y;
        
        % Remove extrapolated pieces of y
        zf(:,k)=y(end-nf:-1:nf+1);
    end
end
