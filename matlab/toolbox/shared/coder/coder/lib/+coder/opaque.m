%CODER.OPAQUE declare a variable in the generated C/C++ code.
%
%   X = CODER.OPAQUE('TYPE','VALUE') declares variable X of type TYPE
%   initialized to VALUE in the generated code.
%
%   X cannot be set or accessed from your MATLAB code, but it can be
%   passed to external C functions, which can read or write the value.
%
%   X can be a variable or a structure field.
%
%   TYPE must be a string constant that represents a C type that
%   supports copying by assignment, such as 'FILE*'.  TYPE will
%   appear in the generated code verbatim and must be a legal prefix
%   in a C declaration.
%
%   VALUE must be a constant string, such as 'NULL'.
%
%   X = CODER.OPAQUE('TYPE') declares variable X of type TYPE with no
%   initial value in the generated C code. The variable must be
%   initialized on all paths prior to its use, using one of the
%   following methods:
%     - Assigning a value from other opaque variables.
%     - Assigning a value from external C functions.
%     - Passing its address to an external function via coder.wref.
%
%   X = CODER.OPAQUE('TYPE','HeaderFile',HeaderFile) declares variable X of
%   type TYPE. The type definition is defined in the file named in the
%   HeaderFile parameter.
%
%   X = CODER.OPAQUE('TYPE','VALUE','HeaderFile',HeaderFile) declares
%   variable X of type TYPE initialized to VALUE in the generated code. The
%   type definition is defined in the file named in the HeaderFile
%   parameter.
%
%   X = CODER.OPAQUE('TYPE',...,'Size',Size) uses Size as the size in bytes for
%   the variable X while generating code. If not specified, the default value is
%   8.
%
%  Example 1:
%    fh = coder.opaque('FILE*', 'NULL');
%    if (condition)
%      fh = coder.ceval('fopen', ['file.txt', int8(0)], ['r', int8(0)]);
%    else
%      coder.ceval('myfun', coder.wref(fh));
%    end
%
%  Example 2:
%    x = coder.opaque('int');
%    y = repmat(x, 3, 3); % creates a 3-by-3 array of int in the generated code
%
%  See also coder.wref, coder.ceval.
%
%  This is a code generation function, so the above describes meaning
%  of coder.opaque inside MATLAB source that is compiled via one of
%  code generation products (MATLAB Coder or Simulink Coder).
%
%  If coder.opaque is executed in MATLAB, it returns an opaque object.

%   Copyright 2007-2023 The MathWorks, Inc.

classdef opaque
    properties(SetAccess=private)
        name (1,1) string
        % Unconditionally making initialValue as char to enable castLike
        % behavior using name (actually type).
        %   cast(22, 'like', coder.opaque('size_t','0'))
        % would generate
        %   (size_t)22
        % Conversion to string would jeopardize this as cast to string
        % errors in MATLAB.
        initialValue char
        headerFile (1,1) string
        isPointer (1,1) logical
        size (1,1) double
    end
    properties(Hidden)
        supportEntryPointIO logical
    end
    methods
        function obj = opaque(name, initialValue, opts)
            arguments
                name {mustBeTextScalar}
                initialValue {mustBeTextScalar} = ""
                opts.HeaderFile {mustBeTextScalar} = ""
                opts.Size {mustBeNumeric} = 0
                opts.IsPointer {mustBeNumericOrLogical} = false
                opts.SupportEntryPointIO {mustBeNumericOrLogical} = false
            end
            obj.name = name;
            obj.initialValue = initialValue;
            obj.headerFile = opts.HeaderFile;
            obj.size = opts.Size;
            obj.isPointer = opts.IsPointer;
            obj.supportEntryPointIO = opts.SupportEntryPointIO;
        end
        function out = castLike(obj, src)
            out = cast(src, 'like', obj.initialValue);
        end
    end
end
