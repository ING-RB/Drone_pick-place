function [tR,tLags] = xcorrxcovCommon(fcnName,tX,varargin)
%XCORRXCOVCOMMON Shared implementation of tall xcorr and tall xcov.

% Copyright 2019 The MathWorks, Inc.

% Match tall conv: only the first input can be tall.
narginchk(1,5); 
tall.checkIsTall(upper(fcnName),1,tX);
tall.checkNotTall(upper(fcnName),1,varargin{:});
% Match XCORR types: no (u)int64 support.
tX = tall.validateType(tX,fcnName,{'double' 'single' 'uint8' 'int8' ...
    'uint16' 'int16' 'uint32' 'int32', 'logical'},1);

[ySupplied,maxlag,scale] = ...
    matlab.internal.math.parseXcorrOptions(varargin{:});

if ~ySupplied
    % We only support XCORR(A,B,varargin).
    error(message('MATLAB:xcorr:BMustBeVector'));
end
if ~strcmp(scale,'none')
    error(message('MATLAB:bigdata:array:XcorrUnsupportedScale'));
end

% Cross-correlation of two column vectors (to be able to call TALL/CONV).
% Rely on TALL/CONV to error below if tX is not a column vector.
% y has been validated to be a vector; make it a column as in XCORR.
y = varargin{1}(:);

if strcmp(fcnName,'xcov')
    % XCOV(x,y,varargin) is simply XCORR(x-mean(x),y-mean(y),varargin).
    tX = tX - mean(tX);
    y = y - mean(y);
end

% Convolve.
tR = conv(tX,conj(flip(y)));
tNr = numel(tR);

% Pad with zeros.
tNx = numel(tX);
ny = max(numel(y),1); % Use 1 for empty to ensure correct padding later.
tR = iPadHeadOrTail(tR,tNr,tNx,ny,abs(tNx-ny));

if ~isempty(maxlag)
    % User-provided maxlag. Clip and/or pad.
    tR = iClipPadToMaxlag(tR,tNx,ny,maxlag);
end

if nargout == 2
    % LAGS = (-MAXLAG:MAXLAG).'
    tLags = getAbsoluteSliceIndices(tR)-ceil(numel(tR)/2);
end

function tR = iPadHeadOrTail(tR,tNr,tNx,ny,tNz)
% Pad the head or tail of the xcorr result (which satisfies nz <= nr):
%     assert(nz<=nr);
%     if nx >= ny,  r = [zeros(nz,1); r];
%     else          r = [r; zeros(nz,1)];
%     end
% Implemented for tall as:
%     r = [r; r];
%     k = (1:2*nr).';
%     if nx >= ny,  r(k <= nr) = 0; r = r(k >= nr-nz+1);
%     else          r(k > nr) = 0;  r = r(k < nr+nz+1);
%     end
% We expect ny << nx for tall x and short y. Therefore, nz is effectively
% almost equal to nr. Hence, [r; r] is only slightly larger than
% r = [zeros(nz,1); r]; so it is not a huge waste to build [r; r] and clip.
tR = [tR; tR];
% Pad both ways but return only one of them.
tK = getAbsoluteSliceIndices(tR); % (1:2*nr).'
import matlab.bigdata.internal.broadcast;
tRhead = iPadHead(tR,tK,broadcast(tNr),broadcast(tNr-tNz+1));
tRtail = iPadTail(tR,tK,broadcast(tNr),broadcast(tNr+tNz+1));
[tRhead,tRtail] = alignpartitions(tRhead,tRtail);
tR = ternaryfun(tNx >= ny,tRhead,tRtail);

function tR = iPadHead(tR,tK,tNr,tDelta)
tR = elementfun(@iZeroOutHead,tR,tK,tNr); % r(k <= nr) = 0
tI = elementfun(@(k,h) k >= h,tK,tDelta); % k >= nr-nz+1
tR = filterslices(tI,tR);                 % r(k >= nr-nz+1)

function tR = iPadTail(tR,tK,tNr,tDelta)
tR = elementfun(@iZeroOutTail,tR,tK,tNr); % r(k > nr) = 0
tI = elementfun(@(k,t) k < t,tK,tDelta);  % k < nr+nz+1
tR = filterslices(tI,tR);                 % r(k < nr+nz+1)

function r = iZeroOutHead(r,k,nr)
r(k<=nr) = 0;
function r = iZeroOutTail(r,k,nr)
r(k>nr) = 0;

function tR = iClipPadToMaxlag(tR,tNx,ny,maxlag)
% Clip and/or pad to get an output of size 2*maxlag+1:
%     % Clip (but without all the branching in XCORR).
%     m = max(nx,ny);
%     maxlagDefault = m-1;
%     mxl = min(maxlag,maxlagDefault);
%     r = r((m-mxl):(m+mxl));
%     if maxlag > maxlagDefault
%         % Pad to 2*maxlag+1
%         z = zeros(maxlag-maxlagDefault,1);
%         r = [z; r; z];
%     end

% No support for arbitrarily large symmetric padding: r = [z; r; z]
tM = max(tNx,ny);
tMaxlagDefault = tM-1;
tR = clientfun(@iErrorForLargeMaxlag,maxlag > tMaxlagDefault,tR);

% Clip: r = r((m-mxl):(m+mxl))
% using tall logical masking:
%     nr = numel(r); nr2 = ceil(nr/2); k = (1:nr).';
%     r = r(k >= nr2-mxl & k <= nr2+mxl);
tMxl = min(maxlag,tMaxlagDefault);
tNr2 = ceil(numel(tR)/2);
tK = getAbsoluteSliceIndices(tR);
tI = elementfun(@(k,nr2,mxl) k >= nr2-mxl & k <= nr2+mxl,tK,tNr2,tMxl);
tR = filterslices(tI,tR);

function tR = iErrorForLargeMaxlag(tFlag,tR)
if tFlag
    error(message('MATLAB:bigdata:array:XcorrUnsupportedLargeMaxlag'));
end

% Uncomment to add support for SCALE:
%{
function tR = iScaleOutput(tR,tX,y,tNx,scale)
% Match XCORR.
if strcmp(scale,'none')
    return
end
import matlab.bigdata.internal.broadcast;
[tNx,y] = clientfun(@iErrorForDifferentLengths,tNx,broadcast(y));
if strcmp(scale,'biased')
    tScale = tNx;
elseif strcmp(scale,'unbiased')
    tLags = getAbsoluteSliceIndices(tR)-ceil(numel(tR)/2);
    tScale = tNx-abs(tLags); % nx-abs(-lag:lag).'
    tScale = elementfun(@iReplaceWithOne,tScale); % tScale(tScale<=0)=1
else % 'normalized'/'coeff'
    tCxx0 = sum(abs(tX).^2);
    cyy0 = sum(abs(y).^2);
    tScale = sqrt(tCxx0*cyy0);
end
tR = tR./tScale;

function x = iReplaceWithOne(x)
x(x <= 0) = 1;

function [tNx,y] = iErrorForDifferentLengths(tNx,y)
if tNx ~= numel(y)
    error(message('MATLAB:xcorr:NoScale'));
end
%}
