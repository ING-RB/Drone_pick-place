classdef KeywordsCPP
    %KEYWORDSCPP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    Keywords = ["alignas","alignof","and","and_eq","asm","atomic_cancel", ...
        "atomic_commit","atomic_noexcept","auto","bitand","bitor","bool", ...
        "break","case","catch","char","char8_t","char16_t","char32_t", ...
        "class","compl","concept","const","consteval","constexpr", ...
        "constinit","const_cast","continue","co_await","co_return", ...
        "co_yield","decltype","default","delete","do","double", ...
        "dynamic_cast","else","enum","explicit","export","extern","false", ...
        "float","for","friend","goto","if","inline","int","long", ...
        "mutable","namespace","new","noexcept","not","not_eq","nullptr", ...
        "operator","or","or_eq","private","protected","public", ...
        "reflexpr","register","reinterpret_cast","requires","return", ...
        "short","signed","sizeof","static","static_assert","static_cast", ...
        "struct","switch","synchronized","template","this","thread_local", ...
        "throw","true","try","typedef","typeid","typename","union", ...
        "unsigned","using","virtual","void","volatile","wchar_t","while", ...
        "xor","xor_eq","final","override","transaction_safe", ...
        "transaction_safe_dynamic","_Pragma"];
    end
    
    methods
        
        function argNames = resolveInputArgNameKeywordConflicts(obj, inputArgs)
            %resolveInputArgNameKeywordConflicts Checks if the input
            %argument name conflicts with a C++ keyword and outputs the
            %name, edited to avoid conflict if neccessary
            arguments (Input)
                obj
                inputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl
            end
            arguments (Output)
                argNames (1,:) string
            end
            
            % If input args is empty, then return empty string
            if(isempty(inputArgs))
                argNames = string.empty();
                return
            end

            % If not empty, continue with main logic
            argNames = [inputArgs.Name];

            conflictLogical = ismember(argNames, obj.Keywords);
            argNames(conflictLogical) = "_" + argNames(conflictLogical);

            % Note - no warning necessary for arg name changes since this
            % doesn't change much on the C++ side.

            % Note - Assumes arg names prepended with "_" won't conflict
            % with variable names in the method/function body nor other
            % arg names / method names (starting with "_" is invalid name
            % in MATLAB)

        end

        function conflicts = getKeywordConflicts(obj, tokenNames)
            % Returns the token names which conflict with C++ keywords
            arguments (Input)
                obj
                tokenNames (1,:) string
            end
            
            arguments (Output)
                conflicts (1,:) string
            end

            if(isempty(tokenNames))
                conflicts = string.empty(); % nothing to conflict
            else
                conflicts = intersect(tokenNames, obj.Keywords);
            end

        end

    end
end

