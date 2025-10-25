function [B,indrm,indoutlier,lthresh,uthresh,center] = rmoutliers(A,varargin)
%RMOUTLIERS   Remove outliers from data
%
%   B = RMOUTLIERS(A) detects and removes outliers from data. A can be a
%   vector, matrix, table, or timetable. If A is a vector, RMOUTLIERS
%   removes the entries detected as outliers. If A is a matrix or a table,
%   RMOUTLIERS detects outliers for each column and then removes the rows
%   containing outliers.
%
%   B = RMOUTLIERS(A,METHOD) specifies the method used to determine
%   outliers. METHOD must be one of the following: 'median' (default),
%   'mean', 'quartiles', 'grubbs', or 'gesd'.
%
%   B = RMOUTLIERS(A,'percentiles',[LP UP]) detects as outliers all
%   elements which are below the lower percentile LP and above the upper
%   percentile UP. LP and UP must be scalars between 0 and 100 with
%   LP <= UP.
%
%   B = RMOUTLIERS(A,MOVMETHOD,WL) uses a moving window method to determine
%   contextual outliers instead of global outliers. MOVMETHOD can be
%   'movmedian' or 'movmean'.
%
%   B = RMOUTLIERS(...,DIM) reduces the size of A along the dimension DIM.
%   Use DIM = 1 to remove rows and DIM = 2 to remove columns.
%   RMOUTLIERS(A,DIM) first calls ISOUTLIER(A) to detect outliers.
%
%   B = RMOUTLIERS(...,'MinNumOutliers',N) removes rows (columns) that
%   contain at least N outliers. N must be an integer. By default, N = 1.
%
%   B = RMOUTLIERS(...,'ThresholdFactor',P) modifies the outlier detection
%   thresholds by a factor P. See the documentation for more information.
%
%   B = RMOUTLIERS(...,'SamplePoints',X) specifies the sample points X
%   representing the location of the data in A for the moving window
%   methods 'movmedian' and 'movmean'. If the first input A is a table, X
%   can also specify a table variable in A.
%
%   B = RMOUTLIERS(...,'MaxNumOutliers',MAXN) specifies the maximum number
%   of outliers for the 'gesd' method only.
%
%   B = RMOUTLIERS(...,'OutlierLocations',INDOUTLIER) specifies the outlier
%   locations according to the logical array INDOUTLIER. Elements of
%   INDOUTLIER that are true indicate outliers in the corresponding element
%   of A. INDOUTLIER must have the same size as A.
%
%   [B,INDRM,INDOUTLIER,LTHRESH,UTHRESH,CENTER] = RMOUTLIERS(...) also
%   returns a logical column (row) vector INDRM indicating which rows
%   (columns) of A were removed, a logical array INDOUTLIER indicating the
%   location of the detected outliers, and the lower threshold, upper
%   threshold, and center value used by the outlier detection method.
%
%   Arguments supported only for table inputs:
%
%   B = RMOUTLIERS(...,'DataVariables',DV) removes rows (variables)
%   according to outliers in table variables DV. The default is all table
%   variables in A. DV must be a table variable name, a cell array of table
%   variable names, a vector of table variable indices, a logical vector, a
%   function handle that returns a logical scalar (such as @isnumeric), or
%   a table vartype subscript.
%
%   Examples:
%
%     % Remove outliers from a vector
%       a = [1 2 1000 3 4 5]
%       b = rmoutliers(a)
%
%     % Remove only the rows which contain at least 2 outliers
%       A = [[1 2 1000 3 4 5]', [1 2 1000 3 4 1000]']
%       [B,removedRows,outlierLocs] = rmoutliers(A,'MinNumOutliers',2)
%
%   See also ISOUTLIER, FILLOUTLIERS, RMMISSING, ISMISSING, FILLMISSING

%   Copyright 2018-2023 The MathWorks, Inc.

if nargout > 2
    [B,indrm,indoutlier,lthresh,uthresh,center] = matlab.internal.math.rmMissingOutliers('rmoutliers',A,varargin{:});
else
    [B,indrm] = matlab.internal.math.rmMissingOutliers('rmoutliers',A,varargin{:});
end
