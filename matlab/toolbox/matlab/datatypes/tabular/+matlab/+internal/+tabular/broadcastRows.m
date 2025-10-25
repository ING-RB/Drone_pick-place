function arrayOut = broadcastRows(arrayIn, nRowsOut, idxRowDest)
%BROADCASTROWS Broadcast array rows into a new (potentially larger) array.
%  ARRAYOUT = BROADCASTROWS(ARRAYIN,NROWSOUT,IDXROWDEST) creates a new
%  array ARRAYOUT with NROWSOUT rows and all rows of ARRAYIN copied into
%  rows IDXROWDEST of ARRAYOUT. Default data are inserted into ARRAYOUT as
%  necessary using matlab.internal.datatypes.defaultarrayLike rules.
%
% If ARRAYIN is a tabular, then most per-array metadata, per-variable
% metadata, and row-labels are copied from ARRAYIN to ARRAYOUT. Exceptions
% include the following timetable properties:
%   - StartTime
%   - SampleRate
%   - TimeStep
%
% If ARRAYIN is N-dimensional, then the size of the non-row dimensions are
% preserved in ARRAYOUT.
%
% e.g. Broadcast table rows.
%   >> t = table((1:3)',table((1:3)','RowNames',{'d','e','f'}),...
%                'RowNames',{'a','b','c'},'VariableNames',{'Var1','t'})
%   t =
%     3×2 table
%            Var1        t    
%                         Var1
%            ____    _________
%       a     1      d     1  
%       b     2      e     2  
%       c     3      f     3  
%   >> broadcastRows(t,5,[1 3 5])
%   ans =
%     5×2 table
%               Var1         t      
%                               Var1
%               ____    ____________
%       a         1     d         1 
%       Row2    NaN     Row2    NaN 
%       b         2     e         2 
%       Row4    NaN     Row4    NaN 
%       c         3     f         3
%
% e.g. Broadcast N-dimensional array rows.
%   >> A = reshape(1:(3^3),3,3,3)
%   A(:,:,1) =
%        1     4     7
%        2     5     8
%        3     6     9
%   A(:,:,2) =
%       10    13    16
%       11    14    17
%       12    15    18
%   A(:,:,3) =
%       19    22    25
%       20    23    26
%       21    24    27
%   >> broadcastRows(A,5,[1 3 5])
%   ans(:,:,1) =
%        1     4     7
%      NaN   NaN   NaN
%        2     5     8
%      NaN   NaN   NaN
%        3     6     9
%   ans(:,:,2) =
%       10    13    16
%      NaN   NaN   NaN
%       11    14    17
%      NaN   NaN   NaN
%       12    15    18
%   ans(:,:,3) =
%       19    22    25
%      NaN   NaN   NaN
%       20    23    26
%      NaN   NaN   NaN
%       21    24    27
%
% See also matlab.internal.datatypes.defaultArrayLike.

% Copyright 2019-2023 The MathWorks, Inc.

if isa(arrayIn,'tabular')
    % Convert row-index to a logical index of the correct size.
    idxRowDestCopy = idxRowDest;
    idxRowDest = false(nRowsOut,1);
    idxRowDest(idxRowDestCopy) = true;
    
    % Copy data and metadata from input array to output array.
    %   tabular/subsasgnParens recursively copies row-labels from the
    %   source array when the output array is a new workspace variable.
    arrayOut(idxRowDest,:) = arrayIn;
    
    % Replace the default data added by tabular/subsasgnParens with that of
    % defaultarrayLike.
    sizeOfDefaultData = [nRowsOut-height(arrayIn),width(arrayIn)];
    arrayOut(~idxRowDest,:) = defaultarrayLike(sizeOfDefaultData,'Like',arrayIn);
else
    szOut = size(arrayIn); szOut(1) = nRowsOut;
    arrayOut = matlab.internal.datatypes.defaultarrayLike(szOut,'Like',arrayIn);
    arrayOut(idxRowDest,:) = reshape(arrayIn,size(arrayIn,1),[]);
end
