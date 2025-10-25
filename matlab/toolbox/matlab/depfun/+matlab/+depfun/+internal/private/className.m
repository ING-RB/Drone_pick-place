function [clsName, clsFile] = className(whichResult, Symbol)
% className Given a path to a file, determine if the file belongs to a class.
% If so, return the name of the class and the path to the class
% constructor.

%   Copyright 2013-2020 The MathWorks, Inc.

    clsName = '';
    clsFile = '';
    
    import matlab.depfun.internal.requirementsConstants
    
    % Check to see if the whichResult is the constructor for a built-in
    % class. There are two kinds of built-in constructors: those inherent
    % to MATLAB (like cell arrays) and those added by toolboxes (like
    % gpuArray).
    if contains(whichResult, requirementsConstants.BuiltInStr)
        nv = requirementsConstants.pcm_nv;
        builtin_registry = nv.builtinRegistry;
        
        if isKey(builtin_registry, Symbol)
            sym = builtin_registry(Symbol);
            type = sym.type;
            if type == matlab.depfun.internal.MatlabType.BuiltinClass
                clsName = Symbol;
                clsFile = builtinClassFile(Symbol, whichResult);
            end
        else
            % Workaround for unregistered built-in symbols,
            % which are not listed in the built-in registry.
            %
            % Two known possible scenarios:
            % 1. Unregistered UDD or MCOS internal built-in classes or
            %    functions, always in the smallest MATLAB Runtime.
            % 2. Built-in static class method, e.g. 'gpuArray.linspace'.            
            
            if matlab.depfun.internal.cacheExist(Symbol,'class') == 8
                % Unregisterdd built-in class, e.g. 'JavaVisible', 'event.listener'
                clsName = Symbol;
                clsFile = builtinClassFile(Symbol, whichResult);
            else
                if contains(Symbol, '.')
                    dotIdx = strfind(Symbol, '.');
                    tmpSymbol = Symbol(1:dotIdx(end)-1);
                    if isKey(builtin_registry, tmpSymbol)
                        sym = builtin_registry(tmpSymbol);
                        type = sym.type;
                        if type == matlab.depfun.internal.MatlabType.BuiltinClass
                            % Unregisterdd built-in class, e.g. 'JavaVisible', 'event.listener'
                            clsName = tmpSymbol;
                            whichResult = matlab.depfun.internal.cacheWhich(clsName);
                            clsFile = builtinClassFile(Symbol, whichResult);
                        end
                    elseif matlab.depfun.internal.cacheExist(tmpSymbol,'class') == 8
                        clsName = tmpSymbol;
                        whichResult = matlab.depfun.internal.cacheWhich(clsName);
                        if contains(whichResult, requirementsConstants.BuiltInStr)
                            clsFile = builtinClassFile(tmpSymbol, whichResult);
                        else
                            clsFile = whichResult;
                        end
                    end
                end
            end
        end
    else
        [clsName, clsFile] = className_impl(whichResult);
    end
end

function clsFile = builtinClassFile(Symbol, whichResult)    
    % Built-in UDD classes would better be classified as
    % UDDClass so their schema.m could be properly included.
    % A side note: Why UDD classes still exist today?!
    [~, clsFile] = classUsingBuiltinCTOR(whichResult);
    if isempty(clsFile)
        [~,clsFile] = virtualBuiltinClassCTOR(Symbol);
    end
    if isempty(clsFile)
        clsFile = whichResult;
    end
end
