function [ySupplied,maxlag,scale] = parseXcorrOptions(varargin)
%parseXcorrOptions Parse all possible varargin from XCORR(x,varargin)
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   XCORR(X),               XCORR(X,Y)
%   XCORR(X,MAXLAG),        XCORR(X,Y,MAXLAG)
%   XCORR(X,SCALE),         XCORR(X,Y,SCALE)
%   XCORR(X,MAXLAG,SCALE),  XCORR(X,Y,MAXLAG,SCALE)
%   XCORR(X,SCALE,MAXLAG),  XCORR(X,Y,SCALE,MAXLAG)
%

%   Copyright 2019 The MathWorks, Inc.

ySupplied = false;
maxlag = [];
scale = 'none';
if nargin < 1
    return
end

% XCORR(x,varargin)
% Preserve legacy parsing for disambiguating between MAXLAG and SCALE
maxlagIdx = 0;
scaleIdx = 0;
stringArg = false(1,nargin);
scalarArg = false(1,nargin);
for k = 1:nargin
    vk = varargin{k};
    stringArg(k) = ischar(vk) || isstring(vk) || iscellstr(vk);
    scalarArg(k) = isscalar(vk);
end
switch nargin
    case 1
        if stringArg(1) % xcorr(x,scale)
            scaleIdx = 1;
        elseif scalarArg(1) % xcorr(x,maxlag)
            maxlagIdx = 1;
        else % xcorr(x,y)
            ySupplied = true;
        end
    case 2
        if scalarArg(1) && stringArg(2) % xcorr(x,maxlag,scale)
            maxlagIdx = 1;
            scaleIdx = 2;
        elseif stringArg(1) && scalarArg(2) % xcorr(x,scale,maxlag)
            maxlagIdx = 2;
            scaleIdx = 1;
        elseif stringArg(2) % xcorr(x,y,scale)
            ySupplied = true;
            scaleIdx = 2;
        else % xcorr(x,y,maxlag)
            ySupplied = true;
            maxlagIdx = 2;
        end
    otherwise % numel(varargin) == 3
        ySupplied = true;
        if stringArg(2) % xcorr(x,y,scale,maxlag)
            maxlagIdx = 3;
            scaleIdx = 2;
        else % xcorr(x,y,maxlag,scale)
            maxlagIdx = 2;
            scaleIdx = 3;
        end
end

if ySupplied
    y = varargin{1};
    if ~isvector(y)
        error(message('MATLAB:xcorr:BMustBeVector'));
    end
    if isnumeric(y)
        if isa(y,'uint64') || isa(y,'int64')
            error(message('MATLAB:xcorr:InvalidSecondInputType'));
        end
    elseif ~islogical(y)
        error(message('MATLAB:xcorr:InvalidSecondInputType'));
    end
end

% Get maxlag
if maxlagIdx > 0
    maxlag = varargin{maxlagIdx};
    if ~isscalar(maxlag) && ~isempty(maxlag)
        error(message('MATLAB:xcorr:MaxLagMustBeScalar'));
    end
    if ~isnumeric(maxlag)
        error(message('MATLAB:xcorr:UnknInput'));
    end
    maxlag = abs(double(maxlag));
    if maxlag ~= floor(maxlag)
        error(message('MATLAB:xcorr:MaxLagMustBeInteger'));
    end
end

% Get scale
if scaleIdx > 0
    scale = varargin{scaleIdx};
    if ~(ischar(scale) || isstring(scale) || iscellstr(scale))
        error(message('MATLAB:xcorr:UnknInput'));
    end
    scale = char(scale);
    if ~isrow(scale)
        error(message('MATLAB:xcorr:UnknInput'));
    end
    slen = length(scale);
    if isempty(scale) || strncmpi(scale,'none',max(slen,3))
        scale = 'none';
    elseif strncmpi(scale,'biased',slen)
        scale = 'biased';
    elseif strncmpi(scale,'unbiased',slen)
        scale = 'unbiased';
    elseif strncmpi(scale,'normalized',max(slen,3)) || ...
            strncmpi(scale,'coeff',slen)
        scale = 'normalized';
    else
        error(message('MATLAB:xcorr:UnknInput'));
    end
end
