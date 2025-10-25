function y = interpn(varargin)
%#codegen

%   Copyright 2024 The MathWorks, Inc.

    % hdl.interpn(X1, X2, X3,. . . V, X1q, X2q, X3q,. . . 'interpolation','extrapolation') 
    % The default value for interpolationMethod and extrapolationMethod is 'linear'
    % V = Sample Values/Table Data
    % X = Sample Points/ Breakpoint data
    % Xq = Grid Vectors

    % Number of provided arguments
    numArgs = nargin;
    
    % Determine the number of dimensions (n) based on the provided arguments
    % Adjust n according to whether interpolation and/or extrapolation values are provided
    if numArgs > 3 && (ischar(varargin{end}) || isstring(varargin{end}))
        % If the last argument is a string, it could be interpolationVal or extrapolationVal
        if numArgs > 4 && (ischar(varargin{end-1}) || isstring(varargin{end-1}))
            % Both interpolationVal and extrapolationVal are provided
            n = (numArgs - 3) / 2;
            numArgs = numArgs-2;

            % inerpolation and extrapolation args must be compile time constant for hdl codegen
            coder.internal.assert(coder.internal.isConst(varargin{end}), ...
                'hdlmllib:hdlmllib:interpnMethodArgMustBeConst');
            coder.internal.assert(coder.internal.isConst(varargin{end-1}), ...
                'hdlmllib:hdlmllib:interpnMethodArgMustBeConst');

            interpolationVal = varargin{end-1};
            extrapolationVal = varargin{end};
        else
            % Only interpolationVal is provided
            n = (numArgs - 2) / 2;
            numArgs = numArgs-1;
            
            % inerpolation and extrapolation args must be compile time constant for hdl codegen
            coder.internal.assert(coder.internal.isConst(varargin{end}), ...
                'hdlmllib:hdlmllib:interpnMethodArgMustBeConst');
            interpolationVal = varargin{end};
            % Set default values for extrapolation
            extrapolationVal = 'linear';
        end
    else
        % Neither interpolationVal nor extrapolationVal is provided
        n = (numArgs - 1) / 2;
        % Set default values for interpolation and extrapolation
        interpolationVal = 'linear';
        extrapolationVal = 'linear';
    end

    if rem(numArgs,2) ~= 1
        error(message('MATLAB:interpn:nargin'));
    end

    % Extract the x vectors (x1, x2, ..., xn)
    X = cell(1,n);
    [X{:}] = varargin{1:n};
    
    % Extract the table data (fd)
    V = varargin{n+1};
    
    % Extract the lookup values (u1, u2, ..., un)
    Xq = cell(1,n);
    [Xq{:}] = varargin{n+2:2*n+1};

    % sample point vectors must be numerical floating point values
    for i = 1:n
        if  ~isnumeric(X{i}) || isfi(X{i})
            error(message('hdlcoder:validate:InvalidInterpnDataType','Input coordinates'));
        end
    end
    
    % sample values must be numerical floating point values
    if  ~isnumeric(V) || isfi(V)
        error(message('hdlcoder:validate:InvalidInterpnDataType','Sample values'));
    end
    
    % input coordinates must be numerical floating point values
    for i = 1:n
        if ~isnumeric(Xq{i}) || isfi(Xq{i})
            error(message('hdlcoder:validate:InvalidInterpnDataType','Input coordinates'));
        end
    end

    % only linear intrapolation method is supported for HDL
    % code generation
    if ~strcmp('linear',interpolationVal)
        error(message('hdlcoder:validate:InvalidInterpnInterpolation'))
    end

    % only linear and nearest extrapolation methods are supported for HDL
    % code generation
    if ~(strcmp('linear',extrapolationVal) ||strcmp('nearest',extrapolationVal))
        error(message('hdlcoder:validate:InvalidInterpnExtrapolation'))
    end

    % grid point samples must be compile time constant for hdl codegen
    for i = 1:n
        coder.internal.assert(coder.internal.isConst(varargin{i}), ...
                'hdlmllib:hdlmllib:interpnGridPointArgMustBeConst');
    end

    % sample values must be compile time constant for hdl codegen
    coder.internal.assert(coder.internal.isConst(varargin{n+1}), ...
                'hdlmllib:hdlmllib:interpnSampleValueArgMustBeConst');

    % The dimensions of 'Table data' and value of 'Number of table
    % dimensions' must match for HDL code generation
    if (n==1 && ~isvector(V)) || (n > 1 && ndims(V) ~= n)
        error(message('hdlcoder:validate:InterpnTableDimensionMismatch',ndims(V),n));
    end
    
    % get table lookup result using griddedInterpolant class
    tluObj = griddedInterpolant(X,V,interpolationVal,extrapolationVal);
    result = tluObj(Xq);
    y = zeros(size(Xq{1}),"like",varargin{1});
    y(:) = result;
end
