function varargout = fevalWithCustomTypeConversion(functionName, lhsCustomTypeInfo, inputs)
    % Thin wrapper for feval which adds support for custom types.

    %  Copyright 2024 The MathWorks, Inc.
    arguments(Input)
        functionName      (1,1) string   % name of the function that feval will be run
        lhsCustomTypeInfo (1,:) struct   % info on outputs that have custom types
    end
    arguments(Input, Repeating)
        inputs % Varargin inputs that will be forwarded to feval
    end

    numInputs = length(inputs); % num inputs to be forwarded to feval
    fevalInputs = inputs; % holds inputs that will go to the regular feval call

    % check if each input is a custom type and transform it if necessary to
    % be compatible with regular feval
    for k = 1:numInputs
        arg = inputs{k};

        if isstruct(arg)
            if isfield(arg, "MATLABCompatibleStruct")
                if arg.MATLABCompatibleStruct

                    libName = arg.LibraryName; % the name of the C++ Interface Library
                    cppName = arg.CPPName; % the struct name in C++
                    address = arg.Address; % where the CPP-owned struct resides
                    isConst = arg.IsDataConst; % if data is const

                    % call builtin to unwrap the special struct and put it in a clib object
                    clibObj = matlab.engine.internal.getClibObjectFromCppAddress(libName, cppName, address, isConst);

                    % place the object in the inputs which will go to feval
                    fevalInputs{k} = clibObj;
                end
            end
        end
    end

    % call feval, now that any custom types have been transformed
    % into clib style objects
    if nargout > 0
        [varargout{1:nargout}] = feval(functionName, fevalInputs{:});
    else
        feval(functionName, fevalInputs{:});
    end

    % Using input info about expected output types, convert custom
    % types from mcos objects to corresponding C++ type. Also, MATLAB releases
    % ownership of data
    if nargout > 0
        for k = 1:length(lhsCustomTypeInfo) % each entry represents a custom output
            customOutArg = lhsCustomTypeInfo(k);
            lhsPosition = customOutArg.OutputPosition;

            if isa(varargout{lhsPosition}, "struct") % check if feval gave us a MATLAB struct, if so, try converting to clib object
                clibConstructor = matlab.engine.internal.getClibTypeNameForCppTypeName(customOutArg.LibraryName, customOutArg.CPPName); % get MATLAB constructor name, given CPP name
                varargout{lhsPosition} = feval(clibConstructor, varargout{lhsPosition});
            end

            % change the clib object to be pointer to underlying data instead
            [structAddress, structCPPType, ~, ~] = matlab.engine.internal.getCppAddressFromClibObjectAndRelease(varargout{lhsPosition});
            varargout{lhsPosition} =  structAddress; % Obj address will be cast to correct pointer type in C++ layer
        end
    end
end