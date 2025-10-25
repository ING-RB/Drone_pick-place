function [B,indrm,indoutlier,lthresh,uthresh,center] = rmoutliers(A,varargin)
%RMOUTLIERS   Remove rows or columns with outliers
%
%   B = RMOUTLIERS(A)
%   B = RMOUTLIERS(A,METHOD)
%   B = RMOUTLIERS(A,MOVMETHOD,WINDOW)
%   B = RMOUTLIERS(...,DIM)
%   B = RMOUTLIERS(...,Name,Value)
%   [B,INDRM,INDOUTLIER,LTHRESH,UTHRESH,CENTER] = RMOUTLIERS(...)
%
%   Limitations:
%   1) The 'percentiles', 'grubbs', and 'gesd' methods are not supported.
%   2) The 'movmedian' and 'movmean' methods do not support tall
%      timetables.
%   3) The 'SamplePoints' and 'MaxNumOutliers' name-value pairs are not
%      supported. 
%   4) The value of 'DataVariables' cannot be a function_handle.
%   5) Computation of RMOUTLIERS(A), RMOUTLIERS(A,'median',...), or
%      RMOUTLIERS(A,'quartiles',...) along the first dimension is only
%      supported for tall column vectors A.
%   6) RMOUTLIERS(A,2) is not supported for tall tables.
%   7) Table and timetable inputs are not supported for
%      ''OutlierLocations'' argument.
%
%   See also RMOUTLIERS, TALL/ISOUTLIER, TALL/FILLOUTLIERS

% Copyright 2018-2024 The MathWorks, Inc.

[B,indrm,indoutlier,lthresh,uthresh,center] = rmMissingOutliers('rmoutliers',A,varargin{:});
