classdef FunctionDescriptor
    %FunctionDescriptor Meta-class for info on a C/C++/Java/MATLAB function
    %   FunctionDescriptor class is used to store the library and function 
    %   name of a validation, factory value, or upgrade function, which is 
    %   defined in C/C++ or Java.  Optionally, can be used for MATLAB
    %   functions, too.

%   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = immutable)
        
        FunctionName string
        Language string {languageMustBeOneOf(Language)} = "MATLAB"
        LibraryName string
        
    end
    
    methods (Access = public)
        
        function obj = FunctionDescriptor(...
            functionName, language, libraryName)
            %FunctionDescriptor class constructor
                            
            if ~isValidInputName(functionName)
                error(message('MATLAB:settings:config:IllegalFunctionName'));
            end
            
            languageMustBeOneOf(language);
           
            if (language == "Java")
                isValid = isValidJavaPath(libraryName);
                if ~isValid
                    error(message('MATLAB:settings:config:IllegalLibraryName'));
                end
            elseif (language == "C") 
                isValid = isValidLibraryName(libraryName);
                if ~isValid
                    error(message('MATLAB:settings:config:IllegalLibraryName'));
                end
            end
            
            obj.FunctionName = functionName;
            obj.Language = language;
            obj.LibraryName = libraryName;
        end
    end
end

function out = isValidInputName(name)
    out = (ischar(name) && ~isempty(name)) || ...
        (isstring(name) && ~isempty(name) && ~ismissing(name) ...
        && ~(name == ""));
end

function out = isValidJavaPath(libraryName)
    persistent matchingSubStr;
    matchingSubStr = '([a-z0-9_]+\.)*[a-z0-9_]+';
    
    out = isValidInputName(libraryName);
    
    if out       
        res = regexpi(libraryName, matchingSubStr, 'match');
        
        if ~strcmp(res(1), libraryName)
            out = false;
        end
    end  
end

function out = isValidLibraryName(libraryName)
    persistent matchingSubStr;
    matchingSubStr = '([a-z0-9_]+\/)*[a-z0-9_]+';
    
    out = isValidInputName(libraryName);
    
    if out       
        res = regexpi(libraryName, matchingSubStr, 'match');
        
        if ~strcmp(res(1), libraryName)
            out = false;
        end
    end  
end

function languageMustBeOneOf(language)
    if ~isValidInputName(language) || ...
        ~ismember(language, ["MATLAB", "C", "Java"])
        throw(MException(message(...
            'MATLAB:settings:config:UnsupportedLanguage')));
    end
end

