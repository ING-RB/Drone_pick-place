function [B,I] = rmmissing(A,varargin)
%RMMISSING   Remove rows or columns with missing entries
%   Standard missing data is defined as:
%      NaN                  - for double and single floating-point arrays
%      NaN                  - for duration and calendarDuration arrays
%      NaT                  - for datetime arrays
%      <missing>            - for string arrays
%      <undefined>          - for categorical arrays
%      empty character {''} - for cell arrays of character vectors
%
%   B = RMMISSING(A) removes missing entries from a vector, or rows with
%   missing entries from a matrix or table.
%
%   B = RMMISSING(A,DIM) reduces the size of A along the dimension DIM.
%   DIM = 1 removes rows, and DIM = 2 removes columns with missing entries.
%   If A is a table, DIM = 2 removes table variables. By default, RMMISSING
%   reduces the size of A along its first non-singleton dimension: it
%   removes rows from matrices and tables.
%
%   B = RMMISSING(A,...,'MinNumMissing',N) removes rows (columns) that
%   contain at least N missing entries. N must be an integer. By default,
%   N = 1.
%
%   [B,I] = RMMISSING(A,...) also returns a logical column (row) vector I
%   indicating which rows (columns) of A were removed.
%
%   Arguments supported only for table inputs:
%
%   B = RMMISSING(A,...,'DataVariables',DV) removes rows according to
%   missing data in table variables DV. The default is all table variables
%   in A. DV must be a table variable name, a cell array of table variable
%   names, a vector of table variable indices, a logical vector, a function 
%   handle that returns a logical scalar (such as @isnumeric), or a table 
%   vartype subscript.
%
%   Examples:
%
%     % Remove NaN entries from a vector
%       a = [NaN 1 2 NaN NaN 3]
%       b = rmmissing(a)
%
%     % Remove only rows that contain at least 2 missing entries
%       A = [NaN(1,3); 13 1 -20; NaN(4,1) ones(4,2); -1 7 -10; NaN(1,3)]
%       B = rmmissing(A,'MinNumMissing',2)
%
%     % Remove table rows that contain standard missing data
%       v1 = {'AB'; ''; ''; 'XYZZ'; 'CDE'};
%       v2 = [NaN; -1; 8; 10; 4];
%       v3 = categorical({'yes'; '--'; 'yes'; 'no'; 'yes'},{'yes' 'no'});
%       T = table(v1,v2,v3)
%       U = rmmissing(T)
%
%     % Ignore rows with NaN entries when using sortrows
%       a = [ [20 10 NaN 30 -5]', [1:5]' ]
%       [b,ia] = rmmissing(a)
%       a(~ia,:) = sortrows(b)
%
%   See also ISMISSING, STANDARDIZEMISSING, FILLMISSING, ISNAN, ISNAT
%            RMOUTLIERS, FILLOUTLIERS

%   Copyright 2015-2023 The MathWorks, Inc.

[B,I] = matlab.internal.math.rmMissingOutliers('rmmissing',A,varargin{:});
