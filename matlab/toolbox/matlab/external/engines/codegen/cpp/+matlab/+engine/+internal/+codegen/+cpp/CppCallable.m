classdef CppCallable
    %CppCallable Represents a C++ callable (method or function)
    %   Represents and generates the C++ callable. This class contains
    %   common code that is generally applicable to callables to prevent
    %   duplicated code
    
    %   Copyright 2023 The MathWorks, Inc.
    
    properties
        Callable (1,1)
        InputArgNamesCPP (1,:) % The input arg names in C++. Name conflicts addressed
    end
    
    methods
        function obj = CppCallable(methodOrFunc)
            %CppCallable Constructor
            %   Handles initialization
            arguments
                methodOrFunc (1,1) {mustBeA(methodOrFunc, ["matlab.engine.internal.codegen.FunctionTpl" "matlab.engine.internal.codegen.MethodTpl"])} %TODO- merge FunctionTpl and MethodTpl so this is not necessary
            end
            obj.Callable = methodOrFunc;

            % Get input arg names with conflicts resolved
            k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
            obj.InputArgNamesCPP = k.resolveInputArgNameKeywordConflicts(obj.Callable.InputArgs);
        end

        
        function sectionContent = string(obj)
            % Construct the string for the method

            import matlab.engine.internal.codegen.*


            if(~obj.Callable.IsAccessible) % Error if method should not be generated
                messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                error(messageObj);
            end

            switch obj.Callable.NumArgOut
                case 0
                    returnType = "void";
                    if(obj.Callable.IsConstructor)
                        returnSection = "[rootIndent][oneIndent][matlabPointer]->feval(u""[EncapsulatingClass]"", 0, _args);";
                    else
                        returnSection = "[rootIndent][oneIndent][matlabPointer]->feval(u""[MethodName]"", 0, _args);";
                    end
                case 1
                    returnType = "matlab::data::Array";
                    if(obj.Callable.IsConstructor)
                        returnSection = "[rootIndent][oneIndent][returnType] _result = [matlabPointer]->feval(u""[EncapsulatingClass]"", _args);" + newline;
                        returnSection = returnSection + "[rootIndent][oneIndent]m_object = _result;";
                    else
                        returnSection = "[rootIndent][oneIndent][returnType] _result = [matlabPointer]->feval(u""[MethodName]"", _args);" + newline;
                        returnSection = returnSection + "[rootIndent][oneIndent]return _result;";
                    end
                otherwise
                    % NumArgOut > 1
                    returnType = "std::vector<matlab::data::Array>";

                    if(obj.Callable.IsConstructor)
                        returnSection = "[rootIndent][oneIndent][returnType] _result = [matlabPointer]->feval(u""[EncapsulatingClass]"", [NumArgOut], _args);" + newline;
                        returnSection = returnSection + "[rootIndent][oneIndent]m_object = _result.at(0);"; % Extra outputs after the first are discarded
                    else
                        returnSection = "[rootIndent][oneIndent][returnType] _result = [matlabPointer]->feval(u""[MethodName]"", [NumArgOut], _args);" + newline;
                        returnSection = returnSection + "[rootIndent][oneIndent]return _result;";
                    end
            end

            % Expand the tokens in the return section
            returnSection = returnSection.replace("[MethodName]", obj.Callable.SectionName);
            returnSection = returnSection.replace("[returnType]", returnType);
            returnSection = returnSection.replace("[NumArgOut]", string(obj.Callable.NumArgOut));

            % Format the arguments to the method

            argsString = ""; % Will be formatted "type1 name1, type2 name2, ..."
            mlArraysString = ""; % Each line of this string will create a MATLAB Data array for each arg
            dims = []; % holds the dimensions of each arg
            dimstrings = []; % used for determining if a dimension is unique
            enumTransformationSection = "";
            vectorTransformationInitSection = "";
            vectorTransformationSection = "";

            if(obj.Callable.IsConstructor || isa(obj.Callable, "matlab.engine.internal.codegen.FunctionTpl")) % Special additional arg if constructor or function
                argsString = "std::shared_ptr<MATLABControllerType> _matlabPtr";
                if(obj.Callable.NumArgIn > 0)
                    argsString = argsString + ", ";
                end
            end

            for i = 1:obj.Callable.NumArgIn
 
                % Create the arg(s) MATLAB can use

                if(i==1)
                    mlArraysString = newline; % Starting newline
                end

                % Skip first arg (is "self" or "obj", so skip) unless
                % constructor or function
                if(i==1 && (~obj.Callable.IsConstructor && ~isa(obj.Callable, "matlab.engine.internal.codegen.FunctionTpl")))
                    mlArraysString = mlArraysString + "[rootIndent][oneIndent][oneIndent]m_object"; % Starting syntax
                    % TODO allow static methods
                    continue;
                end

                if (i == 2 && (~obj.Callable.IsConstructor && ~isa(obj.Callable, "matlab.engine.internal.codegen.FunctionTpl")))
                    mlArraysString = mlArraysString + "," + newline; % Starting syntax
                end


                tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();
                [cppclass, argMatched] = tc.convertArg(obj.Callable.InputArgs(i));

                argname = obj.InputArgNamesCPP(i);

                if(argname == "m_object" || argname == "m_matlabPtr" || argname.startsWith("MATLAB"))
                    % Handle some possible name conflicts with inherited members
                    % TODO We may want to curate a list of such member names or included symbols
                    argname = "_" + argname;
                end

                arrtype = [];
                arrtype = obj.Callable.InputArgs(i).MATLABArrayInfo.SizeClassification;

                % For the case of scalar or 1-D vector
                if ~isempty(cppclass) && ...
                   (arrtype == matlab.engine.internal.codegen.DimType.Scalar || ...
                    arrtype == matlab.engine.internal.codegen.DimType.Vector)

                    %tc = typeConverter();
                    tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();

                    %mclass = obj.Method.ArgMetaData(i).class;
                    mclass = obj.Callable.InputArgs(i).MATLABArrayInfo.ClassName;

                    if(argMatched)

                        argsString = argsString + cppclass + " ";
                        argsString = argsString + argname;

                        % If the cppclass is vector, use iterator-based constructor
                        if arrtype == DimType.Vector
                            arrayinit = argname + ".begin(), " + argname + ".end()";
                            mlArraysString = mlArraysString + "[rootIndent][oneIndent]" + ...
                                "[oneIndent]" + "_arrayFactory.createArray" + ...
                                "({1," + argname +".size()}" + ", " + ...
                                arrayinit + ")";
                        elseif arrtype == DimType.MultiDim
                            % if multi-dim it should be MDA already - no construction of MDA necessary
                            mlArraysString = mlArraysString + "[rootIndent][oneIndent][oneIndent]" + argname;
                        else % assume "scalar", specify template and init vector in-situ
                            arrayinit = "{" + argname + "}";
                            mlArraysString = mlArraysString + "[rootIndent][oneIndent]" + ...
                                "[oneIndent]" + "_arrayFactory.createArray" + ...
                                "<" + cppclass + ">" + "({1,1}" + ", " + ...
                                arrayinit + ")";
                        end

                        % If not a MathWorks restricted class and not empty, assume the class will be generated by user
                    elseif ~tc.isMathWorksRestricted(mclass) && mclass ~= ""

                        % Use same class name in C++ as in MATLAB.
                        % Packages in MATLAB become namespaces in C++
                        translatedClass = string(replace(mclass, ".", "::"));

                        % Perform transformations from C++ generated class type to matlab::data::Array types.
                        % Also handles generated C++ scoped enum conversions

                        isEnumArg = obj.Callable.InputArgs(i).MATLABArrayInfo.IsEnum;

                        % If type is scalar, mda transfer is simple
                        if(arrtype == DimType.Scalar)

                            if(isEnumArg)
                                getStringFuncCall = "get" + replace(mclass, ".", "_") + "String(" + argname +")";
                                enumTransformationSection = enumTransformationSection + "[rootIndent][oneIndent]matlab::data::Array " + "_" + argname + ...
                                     "_Enum = _arrayFactory.createEnumArray({1,1}, """ + mclass + """, {" + getStringFuncCall + "});" + newline;
                                mdaStr = "_" + argname + "_Enum";
                            else
                                mdaStr = argname;
                            end

                        % If type is vector, add std::vector and concatenate for transfer to MATLAB
                        elseif(arrtype == DimType.Vector)
                            if(isEnumArg)
                                % get vector of strings representing the vector of enum values
                                % then use createEnumArray to make the matlab::data::Array to pass to MATLAB

                                vectorTransformationSection = vectorTransformationSection + "[rootIndent][oneIndent]std::vector<std::string> _" + argname + "_EnumStrVector(" + argname + ".size());" + newline + ...
                                    "[rootIndent][oneIndent]std::transform(" + argname + ".begin(), " + argname + ".end(), " + "_" + argname + "_EnumStrVector.begin(), " + "get" + replace(mclass, ".", "_") + "String" + ");" + newline + ...
                                    "[rootIndent][oneIndent]matlab::data::Array _" + argname + "_EnumArray = _arrayFactory.createEnumArray({1," + argname + ".size()}, """ + mclass + """, " + "_" + argname + "_EnumStrVector);" + newline;
                                mdaStr = "_" + argname + "_EnumArray";
                                translatedClass = "std::vector<" + translatedClass + ">";  % wrap in std::vector in C++
                            else
                                vectorTransformationInitSection = "[rootIndent][oneIndent]std::vector<matlab::data::Object> _objHolder;" + newline + ...
                                    "[rootIndent][oneIndent]matlab::data::Array _mda;" + newline + ...
                                    "[rootIndent][oneIndent]size_t _numobj;" + newline + newline;

                                translatedClass = "std::vector<" + translatedClass + ">";
                                 concatAlgorithm = "[rootIndent][oneIndent]_numobj = " + argname + ".size();" + newline + ...
                                    "[rootIndent][oneIndent]_objHolder.clear();" + newline + ...
                                    "[rootIndent][oneIndent]for(size_t _i=0; _i<_numobj; _i++) {" + newline + ...
                                    "[rootIndent][oneIndent][oneIndent]_mda = " + argname + "[_i];" + newline + ...
                                    "[rootIndent][oneIndent][oneIndent]_objHolder.push_back(((matlab::data::ObjectArray)_mda)[0]);" + newline + ...
                                    "[rootIndent][oneIndent]}" + newline + ...
                                    "[rootIndent][oneIndent]matlab::data::ObjectArray " + "_" + argname + "_ConcatArray = " + ...
                                    "_arrayFactory.createArray({1,_numobj}, _objHolder.begin(), _objHolder.end());" + ...
                                    newline + newline;
                                vectorTransformationSection = vectorTransformationSection + concatAlgorithm;
                                mdaStr = "_" + argname + "_ConcatArray";
                            end
                        elseif(arrtype == DimType.MultiDim) % Branch for MultiDim case
                            % High dimension MATLAB object case. Just pass as an MDA
                            translatedClass = "matlab::data::Array";
                            mdaStr = argname;
                        else
                            messageObj = message("MATLAB:engine_codegen:ArgumentHasInvalidDimensions", obj.Callable.MethodPath);
                            error(messageObj);
                        end

                        % Add the arg to the method signature
                        argsString = argsString + translatedClass + " "; %TODO add some way to check for class naming conflicts where possible
                        argsString = argsString + argname;

                        % Add the final MDA for passing to MATLAB
                        mlArraysString = mlArraysString + "[rootIndent][oneIndent][oneIndent]" + mdaStr;
                    else
                        % MATLAB class shipped by MathWorks don't need to generate C++ code
                        argsString = argsString + "matlab::data::Array ";
                        argsString = argsString + argname;
                        mlArraysString = mlArraysString + "[rootIndent][oneIndent][oneIndent]" + argname;
                    end
                else % for empty / higher dim
                    % For the case of higher-dimensional array or failed
                    % type check, use generic matlab::data::Array
                    argsString = argsString + "matlab::data::Array ";
                    argsString = argsString + argname;
                    mlArraysString = mlArraysString + "[rootIndent][oneIndent][oneIndent]" + argname;
                end

                if i ~= obj.Callable.NumArgIn
                    argsString = argsString + ", "; % Add continuations for next arg
                    mlArraysString = mlArraysString + "," + newline;
                end

            end % end of input args loop

            obj.Callable.SectionContent = "[namespaceSection]" + ...
                "[rootIndent][returnType] [MethodName]([argsString]) { " + newline +...
                "[rootIndent][oneIndent]matlab::data::ArrayFactory _arrayFactory;" + newline +...
                "[enumTransformationSection]" + ...
                "[vectorTransformationInitSection]" + ...
                "[vectorTransformationSection]" + ...
                "[rootIndent][oneIndent]std::vector<matlab::data::Array> _args = {" + ...
                "[mlArraysString]" + " };" + newline + ...
                "[returnSection]" + newline + ...
                "[rootIndent]}" + "[namespaceClose]" + newline + newline;

            if(obj.Callable.IsConstructor) % if the method is constructor, it's a bit different
                obj.Callable.SectionContent =  ...
                    "[rootIndent][MethodName]([argsString]) : " + newline + ...
                    "[rootIndent][oneIndent][objectType]()" + newline + ... % Empty base constructor to start, object type depends on handle or value class
                    "[rootIndent]{ " + newline +...
                    "[rootIndent][oneIndent][matlabPointer] = _matlabPtr;" + newline + ... % Set to given MATLAB instance
                    "[rootIndent][oneIndent]matlab::data::ArrayFactory _arrayFactory;" + newline +...
                    "[enumTransformationSection]" + ...
                    "[vectorTransformationInitSection]" + ...
                    "[vectorTransformationSection]" + ...
                    "[rootIndent][oneIndent]std::vector<matlab::data::Array> _args = {" + ...
                    "[mlArraysString]" + " };" + newline + ...
                    "[returnSection]" + newline + ...
                    "[rootIndent]}" + newline + newline;
            end

            % Output type support - 1st of 3 logic blocks for output type support
            if string(getenv('OutputTypeSupport'))=="true"
                OutputsVersion = 2;
            else
                OutputsVersion = 2;
            end
            if(~obj.Callable.IsConstructor && obj.Callable.NumArgOut>0 && OutputsVersion == 2) % only apply templated output design if required

                % Layout the function specializations only.
                % Any subsequent overloading should work as expected on these.

                %%%fullClassParts = split(obj.Callable.EncapsulatingClass, ".");
                %%%classname = fullClassParts(end); % extract class name with no dot notation prefix
                obj.Callable.SectionContent = ""; % Delete any non-templated design
                for i = 0 : obj.Callable.NumArgOut % starts at 0 to include the void case
                    obj.Callable.SectionContent =  obj.Callable.SectionContent + ...
                        "[rootIndent]template<>" + newline + ...
                        "[rootIndent][returnType"+i+"] [ClassPrefix][MethodName]<"+i+">([argsString]) { " + newline +...  %%%"[rootIndent][returnType"+i+"] "+classname+"::[MethodName]<"+i+">([argsString]) { " + newline +...
                        "[rootIndent][oneIndent]matlab::data::ArrayFactory _arrayFactory;" + newline +...
                        "[enumTransformationSection]" + ...
                        "[vectorTransformationInitSection]" + ...
                        "[vectorTransformationSection]" + ...
                        "[rootIndent][oneIndent]std::vector<matlab::data::Array> _args = {" + ...
                        "[mlArraysString]" + " };" + newline + ...
                        "[returnSection"+i+"]" + newline + ...
                        "[rootIndent]}" + newline + newline;
                end


            end


            originalCallable = strip(obj.Callable.SectionContent); % a copy of the original method/function which may be overloaded

            % If any of the input args are complex, we should overload
            % so user can provide them all as real params if they want
            argsStringOverload = "";
            mlArraysStringOverload = "";
            if(argsString.contains("std::complex<"))
                % edit occurrences of "std::complex<T>" to T
                % supports std::complex<T> -> T and std::vector<std::complex<T>> -> std::vector<T> for simple T
                realOverloadSection = strip(obj.Callable.SectionContent);
                argsStringOverload = argsString;
                pattern='std::complex<(\w+)>';
                [tokens, match] = regexp(argsStringOverload, pattern, 'tokens', 'match');
                for i=1:length(tokens)
                    argsStringOverload = replace(argsStringOverload, match(i), tokens{i});
                end

                mlArraysStringOverload = mlArraysString;
                pattern='std::complex<(\w+)>';
                [tokens, match] = regexp(mlArraysStringOverload, pattern, 'tokens', 'match');
                for i=1:length(tokens)
                    mlArraysStringOverload = replace(mlArraysStringOverload, match(i), tokens{i});
                end

                realOverloadSection = replace(originalCallable, "[argsString]", "[argsStringOverload]");
                realOverloadSection = replace(realOverloadSection, "[mlArraysString]", "[mlArraysStringOverload]");
                obj.Callable.SectionContent = realOverloadSection + newline + obj.Callable.SectionContent;
            end

            % If input is varargin then provide 1 overload with 1 generic
            % input of std::vector<matlab::data::Array>
            % so user can supply any combination of valid inputs

            argsStringGenericOverload = "";

            if(obj.Callable.IsVarargin)
                % Construct varargin signature (matlabPtr, vector MDA)
                args = strip(split(argsString,","));
                newArgs = args(1);
                newArgs(2) = "std::vector<matlab::data::Array> _args";

                if(obj.Callable.IsConstructor)
                    argsStringGenericOverload = newArgs(1) + ", " + newArgs(2);

                    overloadGenericSection = "[rootIndent][MethodName]([argsStringGenericOverload]) { " + newline + ...
                        "[rootIndent][oneIndent][matlabPointer] = _matlabPtr;" + newline + ... % Set to given MATLAB instance
                        "[returnSection]" + newline + ...
                        "[rootIndent]}";

                % Method vs function specific content for varargin
                elseif(isa(obj.Callable, "matlab.engine.internal.codegen.MethodTpl"))

                    % 2nd (2/4) logic block for output type support (for methods)
                    % Apply template preamble and class prefix if a template specialization
                    if(~obj.Callable.IsConstructor && obj.Callable.NumArgOut>0 && OutputsVersion == 2)
                        argsStringGenericOverload = "std::vector<matlab::data::Array> args";
                        overloadGenericSection = "[rootIndent]template<>" + newline + ...
                            "[rootIndent][returnType"+ obj.Callable.NumArgOut +"] [ClassPrefix][MethodName]<"+ obj.Callable.NumArgOut +">([argsStringGenericOverload]) { " + newline + ...
                            "[rootIndent][oneIndent]std::vector<matlab::data::Array> _args = { m_object };" + newline + ...
                            "[rootIndent][oneIndent]_args.insert(_args.end(), args.begin(), args.end());" + newline + ...
                            "[returnSection"+ obj.Callable.NumArgOut +"]" + newline + ...
                            "[rootIndent]}";
                    else
                        argsStringGenericOverload = "std::vector<matlab::data::Array> args";
                        overloadGenericSection = "[rootIndent][returnType] [MethodName]([argsStringGenericOverload]) { " + newline + ...
                            "[rootIndent][oneIndent]std::vector<matlab::data::Array> _args = { m_object };" + newline + ...
                            "[rootIndent][oneIndent]_args.insert(_args.end(), args.begin(), args.end());" + newline + ...
                            "[returnSection]" + newline + ...
                            "[rootIndent]}";
                    end
                elseif(isa(obj.Callable, "matlab.engine.internal.codegen.FunctionTpl"))
                    % Unsure unique input signature of overload by using
                    % vector of MDA
                    args = strip(split(argsString,","));
                    newArgs = args(1);
                    newArgs(2) = "std::vector<matlab::data::Array> _args";
                    argsStringGenericOverload = newArgs(1) + ", " + newArgs(2);

                    % 2nd (2/4) logic block for output type support (for functions)
                    % If template design is used, add template preample and remove namespace open/closure
                    if(obj.Callable.NumArgOut>0 && OutputsVersion == 2)
                        overloadGenericSection = "[rootIndent]template<>" + newline + ...
                            "[rootIndent][returnType"+ obj.Callable.NumArgOut +"] [MethodName]<"+ obj.Callable.NumArgOut +">([argsStringGenericOverload]) { " + newline + ...
                            "[returnSection"+ obj.Callable.NumArgOut +"]" + newline + ...
                            "[rootIndent]}";
                    else
                        overloadGenericSection = "[namespaceSection][rootIndent][returnType] [MethodName]([argsStringGenericOverload]) { " + newline + ...
                            "[returnSection]" + newline + ...
                            "[rootIndent]}[namespaceClose]";
                    end
                end

                obj.Callable.SectionContent = ""; % delete previous versions which have limited usability anyways
                % If metadata for plain varargin cases improve, we may consider other options

                obj.Callable.SectionContent = obj.Callable.SectionContent + newline + overloadGenericSection + newline + newline;

            end


            % 3rd (3/4) logic block for output type support
            if(~obj.Callable.IsConstructor && obj.Callable.NumArgOut>0 && OutputsVersion == 2) % only apply templated output design if required

                % Fill-in the return sections
                obj.Callable.SectionContent = matlab.engine.internal.codegen.cpp.utilcpp.writeReturnSection(obj.Callable.OutputArgs, obj.Callable, obj.Callable.SectionContent);

            end

            % Expand all the tokens
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[returnType]", returnType);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[argsString]", argsString);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[argsStringOverload]", argsStringOverload);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[enumTransformationSection]", enumTransformationSection);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[vectorTransformationInitSection]", vectorTransformationInitSection);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[vectorTransformationSection]", vectorTransformationSection);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[mlArraysString]", mlArraysString);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[mlArraysStringOverload]", mlArraysStringOverload);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[argsStringGenericOverload]", argsStringGenericOverload);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[returnSection]", returnSection);
            % Finish with the following substitutions last, since expansion order may matter

            % Method vs function specific content
            if(isa(obj.Callable, "matlab.engine.internal.codegen.MethodTpl"))
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[MethodName]", obj.Callable.ShortName); % Method uses name without namespace due to class encapsulation
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[matlabPointer]", "m_matlabPtr");
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[namespaceSection]", ""); % handled at class level for methods, fill in with blank
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[namespaceClose]", ""); % handled at class level for methods, fill in with blank
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[EncapsulatingClass]", obj.Callable.EncapsulatingClass); % only for methods

                % Handle naming differences in template specialization between method/function
                fullClassParts = split(obj.Callable.EncapsulatingClass, ".");
                classname = fullClassParts(end); % extract class name with no dot notation prefix
                classPrefix = classname + "::";
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[ClassPrefix]", classPrefix);
                
            elseif(isa(obj.Callable, "matlab.engine.internal.codegen.FunctionTpl"))
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[MethodName]", obj.Callable.ShortName); % Function uses full name in :: notation
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[matlabPointer]", "_matlabPtr");
                [namespaceSection, namespaceClose] = matlab.engine.internal.codegen.cpp.utilcpp.generateNamespace(obj.Callable.FullName);
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[namespaceSection]", namespaceSection);
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[namespaceClose]", namespaceClose);
                obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[ClassPrefix]", ""); % no class prefix if a function
            end

            % 4th (4/4) logic block for output type support
            typeStructDefSection = "";
            typeStructSpecSection = "";
            defaultTemplateSection = "";
            if(~obj.Callable.IsConstructor && obj.Callable.NumArgOut>0 && OutputsVersion == 2) % only apply templated output design if required
                % Move the section content containing template specializations to a separate variable
                obj.Callable.TemplateSpecSection = obj.Callable.SectionContent;
                obj.Callable.SectionContent = "";

                % Method vs function specific content for namespace enclosure
                if(isa(obj.Callable, "matlab.engine.internal.codegen.MethodTpl"))
                    % Lastly, add the helper-struct definition and the default template
                    obj.Callable.SectionContent = "[typeStructDefSection]" + ...
                        "[defaultTemplateSection]" + newline;
                elseif(isa(obj.Callable, "matlab.engine.internal.codegen.FunctionTpl"))
                    % Lastly, add the helper-struct definition and the default
                    % template and enclose in namespace if applicable
                    obj.Callable.SectionContent ="[namespaceSection]" + ...
                        "[typeStructDefSection]" + ...
                        "[defaultTemplateSection]" + ...
                        "[TemplateSpecSection]"+ ...
                        "[namespaceClose]";

                    % Expand namespace
                    obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[namespaceSection]", namespaceSection);
                    obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[namespaceClose]", namespaceClose);
                end

                % Write the struct def and the specializations
                [typeStructDefSection, typeStructSpecSection] = matlab.engine.internal.codegen.cpp.utilcpp.writeTypeStruct(obj.Callable.OutputArgs, obj.Callable);
                obj.Callable.TemplateSpecSection = typeStructSpecSection + obj.Callable.TemplateSpecSection; % Add struct specializations to the specialization section

                if(isa(obj.Callable, "matlab.engine.internal.codegen.FunctionTpl"))
                    % Specializations for C++ functions can be placed
                    % directly after the template declaration (whereas for
                    % methods they must be outside the class level)
                    obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[TemplateSpecSection]", obj.Callable.TemplateSpecSection);
                end

                % Write the default template for the method/function
                tempSection = matlab.engine.internal.codegen.cpp.utilcpp.writeTemplateDefault(obj.Callable.OutputArgs, obj.Callable);
                defaultTemplateSection = tempSection;

                % If default template has inputs that might be complex, provide a real numeric overload
                if argsStringOverload ~= ""
                    defaultTemplateSection = defaultTemplateSection + newline + replace(tempSection,"[argsString]","[argsStringOverload]");
                end

                % If varargin generic input should be provided, add it
                if argsStringGenericOverload ~= ""
                    defaultTemplateSection = defaultTemplateSection + newline + replace(tempSection,"[argsString]","[argsStringGenericOverload]");
                end

                defaultTemplateSection = replace(defaultTemplateSection, "[argsString]", argsString); % Fill in argsString
                defaultTemplateSection = replace(defaultTemplateSection, "[argsStringOverload]", argsStringOverload); % Fill in real overloads
                defaultTemplateSection = replace(defaultTemplateSection, "[argsStringGenericOverload]", argsStringGenericOverload); % Fill in varagin overload
            end
            
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[typeStructDefSection]", typeStructDefSection);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[defaultTemplateSection]", defaultTemplateSection);
            obj.Callable.SectionContent = replace(obj.Callable.SectionContent, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Callable.IndentLevel));

            % Return the generated content
            sectionContent  = obj.Callable.SectionContent;
        end

    end
end