classdef CSharpNonStaticClass < matlab.engine.internal.codegen.csharp.CSharpClass
    %   CSHARPNONSTATICCLASS represents a C# non static class
    %   has the format:
    %   attribute
    %   public class foo{
    %       private dynamic _objrep;
    %       private dynamic _matlab;
    %       [Properties]
    %       [constructors]
    %       [Methods]
    %       [Casts]
    %   }
    
    properties
         Casts string;
         PrivateMemberData string = "[rootIndent][oneIndent]private dynamic _objrep;"+ newline + ...
            "[rootIndent][oneIndent]private dynamic _matlab;"+newline;
         ThrowIfDefault = "[rootIndent][oneIndent]private void ThrowIfDefaultValue()" + newline + ... +
        "[rootIndent][oneIndent]{" + newline + ...
            "[rootIndent][oneIndent][oneIndent]if (_matlab == null || _objrep == null)" + newline + ...
            "[rootIndent][oneIndent][oneIndent]{" + newline + ...
                '[rootIndent][oneIndent][oneIndent][oneIndent]throw new UnsupportedTypeException("[className] object is not initialized.");' + newline + ...
            "[rootIndent][oneIndent][oneIndent]}" + newline + ...
        "[rootIndent][oneIndent]}" + newline
         Attribute = "[MATLABClass([ClassNameWithQuotes])]"
         Properties matlab.engine.internal.codegen.csharp.CSharpProperty;
         Constructors matlab.engine.internal.codegen.csharp.CSharpConstructor;
         % Binds to MATLABClassAttribute in generated code
         IEQuatable string = ":IEquatable<[className]>"
         GeneratedLT logical = false;
         GeneratedLE logical = false;
         GeneratedGT logical = false;
         GeneratedGE logical = false;
    end
    
    methods
        function obj = CSharpNonStaticClass(Class, outerCSharpNamespace)
            obj = obj@matlab.engine.internal.codegen.csharp.CSharpClass(Class, outerCSharpNamespace);
            obj = obj.generateClassOrStruct();
            obj = obj.generateConstructor();
            obj = obj.generateProperties();
            obj = obj.generateCasts();
            obj = obj.generateMethods();
        end

        function content = string(obj)
            content = string@matlab.engine.internal.codegen.csharp.CSharpClass(obj);
            % only keep throw if default value if the class is a value
            % class
            if obj.ClassOrStruct == "struct"
                content = replace(content, "[throwIfDefault]", obj.ThrowIfDefault);
                content = replace(content, "[DefaultConstructorSection]", "");
            else
                content = replace(content, "[throwIfDefault]", "");
                % Handle classes need a default constructor for casting
                % purposes
                content = replace(content, "[DefaultConstructorSection]", "[oneIndent]private [className] (){}" + newline + newline);
            end
            % Needs to stay for cast operation in handle class
            content = replace(content, "[castsSection]", obj.Casts);
            % Binds to MATLABClassAttribute in generated code
            content = replace(content, "[attributeToken]", obj.Attribute);
            content = replace(content, "[ClassNameWithQuotes]", '"' + obj.Name + '"');
            content = replace(content, "[privateMemberData]", obj.PrivateMemberData);
            content = replace(content, "[constructorSection]", obj.buildConstructorString());
            content = replace(content, "[propertySection]", obj.buildPropertyString());
            content = replace(content, "[staticToken]", "");
            content = replace (content, "[IEquatableToken]", obj.IEQuatable);
            content = replace(content , "[IEquatableMethodsSection]", obj.buildIEquatableMethodString);
            content = replace(content, "[className]", obj.Name);
            % "Expand" root indents
            content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Class.IndentLevel));
        end
        

        function constructorString = buildConstructorString(obj)
            constructorString = "";
            for constructor = obj.Constructors
                constructorString = constructorString + constructor.string();
            end
        end

        function propertyString = buildPropertyString(obj)
            propertyString = "";
            for property = obj.Properties
                propertyString = propertyString + property.string();
            end
        end

        function obj = generateClassOrStruct(obj)
            if (~obj.Class.SectionMetaData.HandleCompatible)
                obj.ClassOrStruct = "struct";
            end
        end

        function obj = generateCasts(obj)
            casts = obj.castToMATLABObject();
            casts = casts + obj.castToClass();
            obj.Casts = casts;
        end


        function cast = castToMATLABObject(obj)
            cast = "[rootIndent][oneIndent]public static implicit operator MATLABObject([ClassName] [ClassNameLower]){"+ newline +...
                "[Body]" + newline +...
                "[rootIndent][oneIndent]}" + newline;
            cast = replace(cast, "[ClassName]", obj.Name);
            cast = replace(cast, "[ClassNameLower]", lower(obj.Name));
            cast = replace(cast,"[Body]",generateMATLABObjectCastBody(obj));
        end

        function cast = castToClass(obj)
            cast = "[rootIndent][oneIndent]public static implicit operator [ClassName](MATLABObject _obj){"+ newline +...
                "[rootIndent][oneIndent][Body]" + newline +...
                "[rootIndent][oneIndent]}" + newline;
            cast = replace(cast, "[ClassName]", obj.Name);
            cast = replace(cast,"[Body]",generateClassCastBody(obj));
        end
            

        function obj = generateConstructor(obj)
            obj.Constructors = matlab.engine.internal.codegen.csharp.CSharpConstructor.empty();
            numArgInOptional = matlab.engine.internal.codegen.util.CountNumberOfOptionalInputs(obj.Class.Constructor.SectionMetaData.InputArgs);
            for i = 0 : numArgInOptional
                 for j = 1 : obj.Class.Constructor.SectionMetaData.NumArgOut
                    obj.Constructors = [obj.Constructors, matlab.engine.internal.codegen.csharp.CSharpConstructor(obj.Class.Constructor, i, j, obj.Class.FullName)];
                 end
            end
        end

        function body = generateMATLABObjectCastBody(obj)
            body = "[ThrowToken][ReturnToken]";
            if (obj.ClassOrStruct == "struct") %value type
                %address the case of value type = Default
                body = replace(body,"[ThrowToken]", "[rootIndent][oneIndent][oneIndent]" + lower(obj.Name) + ".ThrowIfDefaultValue();" + newline);
            else %handle type
                body = replace(body,"[ThrowToken]", "");
            end
            %return statement will have the form return position._objrep;
            returnStatement = "[rootIndent][oneIndent][oneIndent]return " + lower(obj.Name) + "._objrep;";
            body = replace(body, "[ReturnToken]", returnStatement);
        end

        function body = generateClassCastBody(obj)
            body = "[DefaultToken][AssignmentToken][ReturnToken]";
            if (obj.ClassOrStruct == "struct") %value type
                %address the case of value type = Default
                body = replace(body,"[DefaultToken]", "[rootIndent][oneIndent]" + obj.Name +" "+ lower(obj.Name) + " = default;" + newline);
            else %handle type
               body = replace(body,"[DefaultToken]", "[rootIndent][oneIndent]" + obj.Name +" "+ lower(obj.Name) + " = new " + obj.Name +"();" + newline);
            end
            assignmentStatement = "[rootIndent][oneIndent][oneIndent]" + lower(obj.Name) + "._objrep = _obj;" + newline;
            % pragma warning needed to handle nullable attribute
            assignmentStatement = assignmentStatement + "#pragma warning disable CS8601, CS8602" + newline;
            assignmentStatement = assignmentStatement + "[rootIndent][oneIndent][oneIndent]" + lower(obj.Name) + '._matlab = typeof(MATLABObject).GetField("Matlab", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic).GetValue(_obj);'+newline;
            assignmentStatement = assignmentStatement + "#pragma warning restore" + newline;
            %return statement will have the form return position._objrep;
            returnStatement = "[rootIndent][oneIndent][oneIndent]return " + lower(obj.Name) + ";";
            body = replace(body, "[ReturnToken]", returnStatement);
            body = replace(body, "[AssignmentToken]", assignmentStatement);
        end

         function obj = generateMethods(obj)
            obj.Methods = matlab.engine.internal.codegen.csharp.CSharpMethod.empty();
            for method = obj.Class.Methods
                numOptionalIn = matlab.engine.internal.codegen.util.CountNumberOfOptionalInputs(method.InputArgs);
                for i = 0 : numOptionalIn
                    %create a method for each output as they are all optional
                    for j = 0 : method.NumArgOut
                        % skip a repeat of gt, ge, lt, or le as these
                        % have predefined implementations
                        if (obj.GeneratedGT && method.SectionName == "gt") || ...
                            (obj.GeneratedGE && method.SectionName == "ge") ...
                            || (obj.GeneratedLT && method.SectionName == "lt") || ...
                            (obj.GeneratedLE && method.SectionName == "le")
                            continue;
                        end
                        if method.SectionName == "lt"
                            obj.GeneratedLT = true;
                        elseif method.SectionName == "le"
                            obj.GeneratedLE = true;
                        elseif method.SectionName == "ge"
                            obj.GeneratedGE = true;
                        elseif method.SectionName == "gt"
                            obj.GeneratedGT = true;
                        end
                        obj.Methods = [obj.Methods, matlab.engine.internal.codegen.csharp.CSharpInstanceMethod(method, i, j, obj.OuterCSharpNameSpace)];
                    end
                end
            end
         end

         function obj = generateProperties(obj)
            obj.Properties = matlab.engine.internal.codegen.csharp.CSharpProperty.empty();
            for property = obj.Class.Properties
                obj.Properties = [obj.Properties, matlab.engine.internal.codegen.csharp.CSharpProperty(property, obj.OuterCSharpNameSpace)];
            end
         end

          function methodString = buildIEquatableMethodString(obj)
            methodString= "[oneIndent]public static bool operator == ([className] obj1, [className] obj2){" + newline + ...
                "[oneIndent][oneIndent]bool ret = obj1._matlab.eq(obj1,obj2);" + newline + ...
                "[oneIndent][oneIndent]return ret;" + newline + ...
                "[oneIndent]}" + newline + newline + ...
                "[oneIndent]public static bool operator != ([className] obj1, [className] obj2){" + newline + ...
                "[oneIndent][oneIndent]bool ret = obj1._matlab.ne(obj1,obj2);" + newline + ...
                "[oneIndent][oneIndent]return ret;" + newline + ...
                "[oneIndent]}" + newline + newline + ...
                "[oneIndent]public override bool Equals (Object obj){" + newline + ...
                "[oneIndent][oneIndent]if (obj == null){" + newline + ...
                "[oneIndent][oneIndent][oneIndent]return false;" + newline + ...
                "[oneIndent][oneIndent]}" + newline + newline + ...
                "[oneIndent][oneIndent]try{" + newline + newline + ...
                "[oneIndent][oneIndent][oneIndent][className] _obj = ([className])obj;" + newline + ...
                "[oneIndent][oneIndent][oneIndent]return (this == _obj);" + newline + ...
                "[oneIndent][oneIndent]}" + newline + newline + ...
                "[oneIndent][oneIndent]catch(Exception){" + newline + newline + ...
                "[oneIndent][oneIndent][oneIndent]return false;" + newline + ...
                "[oneIndent][oneIndent]}" + newline + newline + ...
                "[oneIndent]}" + newline + newline + ...
                "[oneIndent]public bool Equals([className] obj){" + newline + ...
                "[oneIndent][oneIndent]return this == obj;" + newline + ...
                "[oneIndent]}" + newline + newline + ...
                "[oneIndent]public override int GetHashCode(){" + newline + ...
                "[oneIndent][oneIndent]UInt64 hashcode = _matlab.keyHash(_objrep);" + newline + ...
                "[oneIndent][oneIndent]return hashcode.GetHashCode();" + newline + ...
                "[oneIndent]}" + newline + newline;
          end
    end
end

