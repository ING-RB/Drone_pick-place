function rows = selectRows(A, idx)
%SELECTROWS Select rows from an input array.
%  SELECTROWS(A,IDX) Returns the rows of A specified by IDX, which can
%  either be a logical or numeric index. If A is N-dimensional, then the
%  result is reshaped to preserve the size of the additional dimensions.
%
% e.g. Select table rows.
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
%   >> selectRows(t,[1 3])
%   ans =
%     2×2 table
%            Var1        t    
%                         Var1
%            ____    _________
%       a     1      d     1  
%       c     3      f     3
%
% e.g. Select N-dimensional array rows.
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
%   >> selectRows(A,[1 3])
%   ans(:,:,1) =
%        1     4     7
%        3     6     9
%   ans(:,:,2) =
%       10    13    16
%       12    15    18
%   ans(:,:,3) =
%       19    22    25
%       21    24    27

% Copyright 2012-2019 The MathWorks, Inc.

if ismatrix(A)
    rows = A(idx,:);
else
    % A could have any number of dims, no way of knowing, except how many
    % rows it has. So just treat A as 2D to get the necessary rows,
    % and then reshape the remaining dims to the original values.
    sizeOut = size(A);
    if islogical(idx)
        sizeOut(1) = nnz(idx);
    else
        sizeOut(1) = numel(idx);
    end
    rows = reshape(A(idx,:),sizeOut);
end