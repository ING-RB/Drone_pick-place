function matlabType = tempSymbolTypeAdaptor(symbolType, classType, isBuiltin, sym)

import matlab.depfun.internal.MatlabType
%         NotYetKnown         (0) % Not enough info. yet
%         MCOSClass           (1) % Matlab Common Object System
%         UDDClass            (2) % Universal Data Dictionary
%         OOPSClass           (3) 
%         BuiltinClass        (4) % A built-in class-like object (e.g., cell)
%         ClassMethod         (5) % Method of MCOS class or OOPS class
%         UDDMethod           (6) % Method of UDD class, g887983
%         UDDPackageFunction  (7) % UDD package function, 1@, no+
%         Function            (8) % A non-method function
%         BuiltinFunction     (9) % A function implemented in C++
%         BuiltinMethod      (10) % A method of a builtin class
%         BuiltinPackage     (11) % A package registered by a shared library
%         Data               (12) % MATLAB native data (.mat, .fig)
%         Ignorable          (13) % A MATLAB symbol that must be ignored
%         Extrinsic          (14) % A symbol or file from another land
%         DotNetAPI          (15) % External .NET API
%         JavaAPI            (16) % External Java API
%         PythonAPI          (17) % External Python API
%         SimulinkModel      (18) % Simulink Model
%         CppAPI             (19) % External Cpp API

% symbol type
%         SCRIPT
%         FUNCTION
%         NAMESPACE_FUNCTION
%         CLASS_CONSTRUCTOR
%         STATIC_METHOD
%         INSTANCE_METHOD
%         UNDETERMINED

% class type
%         MCOS
%         UDD
%         OOPS
%         JAVA
%         N/A

import matlab.depfun.internal.requirementsConstants

switch (symbolType)
    case 'UNDETERMINED'
        matlabType = MatlabType.NotYetKnown;
    case 'CLASS_CONSTRUCTOR'
        if ~isBuiltin
            switch (classType)
                case 'MCOS'
                    matlabType = MatlabType.MCOSClass;
                case 'UDD'
                    matlabType = MatlabType.UDDClass;
                case 'OOPS'
                    matlabType = MatlabType.OOPSClass;
                case 'JAVA'
                    matlabType = MatlabType.JavaAPI;
                otherwise
                    matlabType = MatlabType.NotYetKnown;
            end
        else
            matlabType = MatlabType.BuiltinClass;
            if strcmpi(classType, 'MCOS') && ~isempty(requirementsConstants.pcm_nv) ...
                    && ~isKey(requirementsConstants.pcm_nv.builtinRegistry, sym)
                matlabType = RefineTypeForDynamicExternalInterface(sym, matlabType);
            end
        end
    case {'STATIC_METHOD' 'INSTANCE_METHOD'}
        if ~isBuiltin
            switch (classType)
                case {'MCOS' 'OOPS'}
                    matlabType = MatlabType.ClassMethod;
                case 'UDD'
                    matlabType = MatlabType.UDDMethod;
                case 'JAVA'
                    matlabType = MatlabType.JavaAPI;
                otherwise
                    matlabType = MatlabType.NotYetKnown;
            end
        else
            matlabType = MatlabType.BuiltinMethod;
        end
    case 'NAMESPACE_FUNCTION'
        matlabType = MatlabType.Function;
        if strcmpi(classType, 'UDD')
            matlabType = MatlabType.UDDPackageFunction;
        elseif isBuiltin && strcmpi(classType, 'MCOS') ...
                && ~isempty(requirementsConstants.pcm_nv) ...
                && ~isKey(requirementsConstants.pcm_nv.builtinRegistry, sym)
            matlabType = RefineTypeForDynamicExternalInterface(sym, matlabType);
        end
    case {'FUNCTION'  'SCRIPT'}
        if ~isBuiltin
            matlabType = MatlabType.Function;
        else
            matlabType = MatlabType.BuiltinFunction;
        end
    otherwise
        matlabType = MatlabType.NotYetKnown;
end
end