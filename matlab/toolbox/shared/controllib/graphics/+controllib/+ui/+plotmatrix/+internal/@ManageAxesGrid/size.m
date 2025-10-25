function varargout = size(this, varargin)
% SIZE Return the number of rows and columns in the axes grid
%
% [nR, nC] = size(this)
%   Outputs: nR - number of rows
%            nC - number of columns
%
% n = size(this, 1)
%   Outputs: n - number of rows
%
% n = size(this, 2)
%   Outputs: n - number of columns

%   Copyright 2015-2020 The MathWorks, Inc.

% Check number of inputs
narginchk(1,2);

if nargin == 2
    % If a dimension was passed in, return size along that
    % dimension
    varargout{1} = this.AxesGrid.Size(varargin{1});
else
    % Else return number of rows and columns
    varargout{1} = this.AxesGrid.Size(1);
    varargout{2} = this.AxesGrid.Size(2);
end
end
