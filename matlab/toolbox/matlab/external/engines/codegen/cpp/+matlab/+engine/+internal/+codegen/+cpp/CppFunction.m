classdef CppFunction < matlab.engine.internal.codegen.cpp.CppCallable
    %CppMethod Represents a C++ function
    %   Represents and generates the C++ function, given
    %   language-agnostic MATLAB metadata
    
    properties
        % Important properties will go here
    end
    
    methods
        function obj = CppFunction(Function)
            %CppFunction Constructor
            obj = obj@matlab.engine.internal.codegen.cpp.CppCallable(Function);
        end

        function sectionContent = string(obj)
            %string generates the C++ function

            sectionContent = string@matlab.engine.internal.codegen.cpp.CppCallable(obj);
        end

        % Helper generation methods will go here
    end
end

