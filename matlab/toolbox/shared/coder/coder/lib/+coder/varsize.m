function varsize(varargin)
%CODER.VARSIZE Declare data to be variable-size
%
%   CODER.VARSIZE('VAR1', 'VAR2', ...) declares one or more variables as
%     variable-size arrays, allowing subsequent assignments to extend
%     their size. Each 'VARn' must be a quoted string that represents a
%     variable, a cell array element, or a structure field.
%     If the structure field is a structure array, use colon (:) as the
%     index expression, indicating that all elements of the array are 
%     variable-size.
%
%     For example, the expression coder.varsize('data(:).A') declares
%     that the field A inside each element of data is variable sized.
%
%   CODER.VARSIZE('VAR1', 'VAR2', ..., UBOUND) declares one or more
%     variables as variable-size data with an explicit upper bound
%     specified in UBOUND. The argument UBOUND must be a constant,
%     integer-valued vector of upper bound sizes for every dimension of
%     each 'VARn'.  If you specify more than one 'VARn', each variable
%     must have the same number of dimensions.
%
%   CODER.VARSIZE('VAR1', 'VAR2', ..., UBOUND, VARDIABLEDIMS) declares
%     variables VARn as variable size arrays with given upper bound
%     UBOUND and varying-dimensions VARIABLEDIMS.  VARDIABLEDIMS must be
%     a logical vector indicating which dimensions vary.
%
%   CODER.VARSIZE('VAR1', 'VAR2', ..., [], VARDIABLEDIMS) declares
%     variables VARn as variable size arrays with a mix of fixed and
%     varying dimensions.  The empty matrix indicates that an upper
%     bound will be determined automatically.
%
%   If VARIABLEDIMS is not given, all dimensions are assumed to vary
%   except the singleton ones. A singleton dimension is any dimension
%   for which size(A,dim) = 1.
%
%   You must add the coder.varsize declaration before each 'VARn' is
%   used (read). 
%
%   If 'VARn' is a cell array element, the coder.varsize declaration
%   must follow the first assignment to that element. For example:
%
%   ...
%   x = cell(3, 3);
%   x{1} = [1 2];
%   coder.varsize('x{1}');
%   ...
%
%   A cell array can be variable-size only if it is homogeneous. Therefore,
%   if 'VARn' is a heterogeneous cell array, coder.varsize tries to convert  
%   it to a homogeneous cell array. coder.varsize tries to find a size and 
%   class that apply to all cells in the cell array. For example, the
%   heterogeneous cell array {[1 2] 3} can become a homogeneous cell array
%   where the base type of each cell is 1x:2 double. If coder.varsize
%   cannot convert 'VARn'to a homogeneous cell array, coder.varsize reports
%   an error. For example, {'a', 1} cannot become a homogeneous cell array
%   because the first cell is a char and the second cell is a double.
%   
%   You cannot apply coder.varsize to global variables. When generating
%   code at the command-line, use a coder.Type object inside the '-global'
%   switch to define variable sized global arrays.
%
%   This is a code generation function.  It has no effect in MATLAB
%   code.
%
%   Example:
%     A simple stack that varies in size up to 32 elements as you push and
%     pop data at runtime.
%
%     function test_stack %#codegen
%         % The optional directive %#codegen documents that the function
%         % is intended for code generation.
%         stack('init', 32);
%         for i = 1 : 20
%             stack('push', i);
%         end
%         for i = 1 : 10
%             value = stack('pop');
%             % Display popped value.
%             value
%         end
%     end
%
%     function y = stack(command, varargin)
%         persistent data;
%         if isempty(data)
%             data = ones(1,0);
%         end
%         y = 0;
%         switch (command)
%         case {'init'}
%             coder.varsize('data', [1, varargin{1}], [0 1]);
%             data = ones(1,0);
%         case {'pop'}
%             y = data(1);
%             data = data(2:size(data, 2));
%         case {'push'}
%             data = [varargin{1}, data];
%         otherwise
%             assert(false, ['Wrong command: ', command]);
%         end
%     end
%
%   The variable 'data' is the stack.  The statement coder.varsize('data',
%   [1, varargin{1}], [0 1]) declares that:
%   * 'Data' is a row vector
%   * Its first dimension has a fixed size
%   * Its second dimension can grow to an upper bound of 32
%


% Copyright 2009-2019 The MathWorks, Inc.
