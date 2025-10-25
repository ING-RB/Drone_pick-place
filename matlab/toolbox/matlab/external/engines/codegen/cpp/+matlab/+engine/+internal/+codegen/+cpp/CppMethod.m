classdef CppMethod < matlab.engine.internal.codegen.cpp.CppCallable
    %CppMethod Represents a C++ method
    %   Represents and generates the C++ method, given
    %   language-agnostic MATLAB metadata
    
    properties
        % Important properties will go here
    end
    
    methods
        function obj = CppMethod(Method)
            %CppMethod Constructor
            obj = obj@matlab.engine.internal.codegen.cpp.CppCallable(Method);
            %obj.Method = Method;
        end

        function sectionContent = string(obj)
            %string Generates the C++ method
            % Note: template specializations outside the class must be
            % handled separately

            sectionContent = string@matlab.engine.internal.codegen.cpp.CppCallable(obj);
        end
        % Helper generation methods will go here
    end
end

