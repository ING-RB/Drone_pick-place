function [X, Y, xy2input ] = getXY(varargin)
%MATLAB Code Generation Private Function
% parse and get the x- and y- coordinates when input is a matrix

%   Copyright 2023 The MathWorks, Inc.

%#codegen

xy2input = false;
xyValSet = false;
for ia=1:numel(varargin)

    if (~isnumeric(varargin{ia}) )
        break;
    end

    if(ia == 2 && xy2input)
        continue
    end

    pts = varargin{ia};

    coder.internal.errorIf(issparse(pts),'MATLAB:polyshape:sparseError');

    %check if input contains one or two numeric arrays
    twoInput = (nargin >= ia+1 && coder.const(isnumeric(varargin{ia+1})) );

    %check if mixture of cell and numeric arrays is passed
    coder.internal.errorIf(nargin >= ia+1 && iscell(varargin{ia+1}), ...
        'MATLAB:polyshape:xyNumericCell');

    coder.internal.errorIf(numel(size(pts)) > 2 && twoInput, 'MATLAB:polyshape:twoInputSizeError');
    coder.internal.errorIf(numel(size(pts)) > 2 && ~twoInput, 'MATLAB:polyshape:oneInputSizeError');

    if ~twoInput
        %g1664687 [0x2], [nan nan] returns empty shape
        %[1 2; 2 2] triggers warning (boundary dropped)
        %0x2 ==> empty polyshape
        %1x2, 2x2 ==> warning of boundary being dropped
        coder.internal.assert(size(pts,2)==2, 'MATLAB:polyshape:oneInputSizeError');
        
        xx = pts(:, 1);
        yy = pts(:, 2);
        coder.internal.errorIf(xyValSet, 'MATLAB:polyshape:multipleDataSetError');
        
        if (size(xx, 1) > 1)
            X = xx';
            Y = yy';
        else
            X = xx;
            Y = yy;
        end

        xy2input = false;

    else
        %two input arrays

        coder.internal.assert(nargin >= ia+1, 'MATLAB:polyshape:oneInputSizeError');

        coder.internal.errorIf(nargin >= ia+1 && ~isnumeric(varargin{ia+1}), ...
            'MATLAB:polyshape:oneInputSizeError');

        coder.internal.assert(isvector(varargin{ia+1}), ...
            'MATLAB:polyshape:twoInputSizeError');

        xx = varargin{ia};
        yy = varargin{ia+1};

        coder.internal.errorIf(issparse(xx) || issparse(yy), ...
            'MATLAB:polyshape:sparseError')
        coder.internal.assert(isequal(size(yy), size(xx)), ...
            'MATLAB:polyshape:twoInputSizeError');

        coder.internal.errorIf(xyValSet, 'MATLAB:polyshape:multipleDataSetError');

        if (size(xx, 1) > 1)
            X = xx';
            Y = yy';
        else
            X = xx;
            Y = yy;
        end
        xy2input = true;
    end

    xyValSet = true;
end
