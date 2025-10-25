function [tC,tLags] = xcov(tA,varargin)
%XCOV Cross-covariance
%
%   C = XCOV(A,B)
%   C = XCOV(A,B,MAXLAG)
%   C = XCOV(___,SCALE)
%   [C,LAGS] = XCOV(___)
%
%   Limitations:
%   1) A must be a tall column vector.
%   2) B must be a non-tall vector.
%   3) XCOV(A) is not supported.
%   4) If supplied, MAXLAG must be smaller than its default value:
%      MAXLAG <= MAX(NUMEL(A),NUMEL(B))-1.
%   5) If supplied, SCALE must be set to 'none'.
%   6) LAGS is always a tall column vector.
%
%   See also xcov, xcorr, tall/xcorr

% Copyright 2019 The MathWorks, Inc.

[tC,tLags] = xcorrxcovCommon('xcov',tA,varargin{:});