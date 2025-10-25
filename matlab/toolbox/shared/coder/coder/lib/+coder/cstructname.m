function Tout = cstructname(Tin, varargin)
%CODER.CSTRUCTNAME Specify structure name in generated code
%
%   CODER.CSTRUCTNAME(VAR, 'NAME') declares that the structure type
%   used for variable VAR should be named NAME in the generated C code.
%   VAR must be a structure or cell array.
%
%   CODER.CSTRUCTNAME(VAR, 'NAME', 'extern') declares that the
%   externally-defined structure type used for variable VAR should be named
%   NAME in the generated C code. Does not generate the definition of the
%   structure type; you must provide the definition in a custom include
%   file.
%
%   CODER.CSTRUCTNAME(VAR, 'NAME', 'extern' [, PROPERTY, 'VALUE'[,
%   PROPERTY, 'VALUE']]) declares that the externally-defined structure
%   type used for variable VAR should be named NAME in the generated
%   C code. Does not generate the definition of the structure type.
%   The definition is provided with the properties specified by optional
%   PROPERTY-VALUE pair, where the PROPERTY can be:
%
%        'HeaderFile'   --- Must be a non-empty string
%        'Alignment'    --- Must be either -1 (default) or a power of 2
%                           that is no more than 128.
%
%   CODER.CSTRUCTNAME(TYPE, ...) returns a coder.StructType with the
%   properties specified by the subsequent arguments if TYPE is a
%   coder.StructType. The returned type can be used with the code
%   generation commands. If TYPE is not a coder.StructType, the behavior is
%   the same as for the CODER.CSTRUCTNAME(VAR, ...) usage.
%
%   The CODER.CSTRUCTNAME(VAR, ...) usage is a code generation function. It
%   has no effect in MATLAB. Conversely, the CODER.CSTRUCTNAME(TYPE, ...)
%   usage is a MATLAB function. It is not legal in code generation.
%
%   You must call coder.cstructname before the first use of VAR.
%
%   If VAR is a cell array element, you must call coder.cstructname after
%   the first assignment to that element. For example:
%
%   ...
%   x = cell(2,2);
%   x{1} = struct('a', 3);
%   coder.cstructname(x{1}, 'mytype');
%   ...
%
%   If VAR is a homogeneous cell array, coder.cstructname  converts
%   it to a heterogeneous cell array. A cell array must be heterogeneous
%   for representation as a structure in the generated C/C++ code.
%
%   Note:  CODER.CSTRUCTNAME cannot be applied to global variables
%   directly.  To set the type name for a global variable, apply
%   CODER.CSTRUCTNAME to the type specified for the global variable.
%
%   Example (code generation):
%     C code:
%       typedef struct { double x; double y; } MyPointType;
%       void foo(const MyPointType* ptr);
%
%     MATLAB code:
%       % Declare a MATLAB structure.
%       var.x = 1;
%       var.y = 2;
%       % Assign the name MyPointType to the type of var.
%       coder.cstructname(var, 'MyPointType', 'extern');
%       % The type of var matches foo's signature.
%       coder.ceval('foo', coder.rref(var));
%
%   Example (MATLAB type definition):
%       S.a = coder.typeof(double(0));
%       S.b = coder.typeof(single(0));
%       T = coder.typeof(S);
%       T = coder.cstructname(T,'mytype','extern','HeaderFile','myheader.h');
%
%   See also coderTypeEditor, coder.varsize, coder.typeof

%   Copyright 2006-2019 The MathWorks, Inc.

    narginchk(2,7);
        
    % If no output this is a code generation function. In MATLAB, it is ignored.
    if nargout == 0
        return;
    end
    
    if coder.internal.isCharOrScalarString(varargin{1}) && strlength(varargin{1}) == 0
        error(message('Coder:builtins:CStructNameEmptyTypeName', bnName));
    end

    Tout = coder.typeof(Tin);

    if ~(isa(Tout, 'coder.StructType') || isa(Tout, 'coder.CellType'))
        error(message('Coder:builtins:CStructNameArg1Class',bnName));
    end

    try
        Tout = doit(Tout, varargin{:});
    catch me
        me.throwAsCaller();
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function T = doit(T, name, extern, varargin)
    if isa(T, 'coder.CellType') && ~all(T.VariableDims == 0)
        error(message('Coder:builtins:CStructNameVarSizeCellArray'));
    end

    T = makeHeterogeneous(T);
    
    T.TypeName = name; % This is a validated assignment
    if nargin == 2
        return;
    end
    % Externally defined type
    if ~isprop(T, 'Extern')
        error(message('Coder:builtins:CStructNameArgExtern', bnName, class(T)));
    end
    if ~coder.internal.isCharOrScalarString(extern) || ~strcmpi(extern, 'extern')
        error(message('Coder:builtins:CStructNameArg3', bnName));
    end
    T.Extern = true;

    % Now do the P-V pairs, HeaderFile and Alignment
    p = inputParser();
    p.FunctionName = bnName;
    p.addParameter('HeaderFile','');
    p.addParameter('Alignment',repmat(int32(0),1,0));
    p.parse(varargin{:});
    r = p.Results;
    if ~isempty(r.HeaderFile)
        if isstring(r.HeaderFile) && strlength(r.HeaderFile) > 0
            T.HeaderFile = char(r.HeaderFile);
        else
            T.HeaderFile = r.HeaderFile;
        end
    end
    if ~isempty(r.Alignment)
        if isa(T, 'coder.CellType')
            error(message('Coder:builtins:CStructNameCellTypeAlignmentUnsupported'));
        end

        T.Alignment = r.Alignment;
    end
end

function T = makeHeterogeneous(T)
    if isa(T, 'coder.CellType')
        T = T.makeHeterogeneous;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = bnName
    s = 'coder.cstructname';
end
