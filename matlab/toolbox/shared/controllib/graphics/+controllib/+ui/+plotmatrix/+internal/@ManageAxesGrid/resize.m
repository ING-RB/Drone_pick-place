function resize(this, varargin)
% RESIZE Change the size (number of rows and columns) of the
% axes grid
%
% resize(AG, n)
%   Inputs: n - number of rows and columns
%
% resize(AG, nR, nC)
%   Inputs: nR - number of rows
%           nC - number of columns

%   Copyright 2015-2020 The MathWorks, Inc.

% Input validation
narginchk(2,3);

if nargin == 2
    % n
    nR = varargin{1};
    nC = varargin{1};
else
    % nR, nC
    nR = varargin{1};
    nC = varargin{2};
end

% Validate inputs
controllib.ui.plotmatrix.internal.ManageAxesGrid.localCheckFcn(nR);
controllib.ui.plotmatrix.internal.ManageAxesGrid.localCheckFcn(nC);

resize_(this, nR, nC);
end
