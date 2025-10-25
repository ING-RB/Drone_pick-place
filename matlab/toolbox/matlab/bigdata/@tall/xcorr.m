function [tC,tLags] = xcorr(tA,varargin)
%XCORR Cross-correlation
%
%   C = XCORR(A,B)
%   C = XCORR(A,B,MAXLAG)
%   C = XCORR(___,SCALE)
%   [C,LAGS] = XCORR(___)
%
%   Limitations:
%   1) A must be a tall column vector.
%   2) B must be a non-tall vector.
%   3) XCORR(A) is not supported.
%   4) If supplied, MAXLAG must be smaller than its default value:
%      MAXLAG <= MAX(NUMEL(A),NUMEL(B))-1.
%   5) If supplied, SCALE must be set to 'none'.
%   6) LAGS is always a tall column vector.
%
%   See also xcorr, xcov, tall/xcov

% Copyright 2019 The MathWorks, Inc.

[tC,tLags] = xcorrxcovCommon('xcorr',tA,varargin{:});