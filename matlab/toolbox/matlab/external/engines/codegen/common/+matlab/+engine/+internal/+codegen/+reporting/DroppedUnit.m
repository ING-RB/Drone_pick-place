classdef DroppedUnit
    %GeneratedUnit Represents a MATLAB code unit that has been dropped
    % from a strongly-typed interface

    %   Copyright 2023 The MathWorks, Inc.
    
    properties
        Type (1,1) matlab.engine.internal.codegen.reporting.UnitType
        DefiningName (1,1) string  % Name of class or func. that defines dropped unit
        Name (1,1) string
        ReasonDropped (1,1) string
        IsImplicit (1,1) logical % Whether user explicitly wanted to generate the item
        OmitWarning (1,1) logical % Option to omit a dropped unit from being in a warning message
    end

    methods
        function obj = DroppedUnit(type, definingName, name, reasonDropped, isImplicit, omitWarning)
            arguments
                type (1,1) matlab.engine.internal.codegen.reporting.UnitType
                definingName (1,1) string  % name of defining class or function
                name (1,1) string  % name of the structure dropped
                reasonDropped (1,1) message
                isImplicit (1,1) logical  % if the struture was explicitly specified to generate by user or not
                omitWarning (1,1) logical % Option to omit a dropped unit from being in a warning message
            end

            obj.Type = type;
            obj.DefiningName = definingName;
            obj.Name = name;
            obj.ReasonDropped = string(reasonDropped.getString());
            obj.IsImplicit = isImplicit;
            obj.OmitWarning = omitWarning;

        end

    end

    methods (Static)
        function strOut = dataToString(data)
            %dataToString used to print data on an array of "DroppedUnit"s for use
            % in warning/error messages and reporting printouts

            arguments
                data (1,:) matlab.engine.internal.codegen.reporting.DroppedUnit
            end

            m = containers.Map();
            sortedClassData = [];
            sortedFunctionData = [];
            strOut = "";

            if(~isempty(data))

                for i = 1 : length(data)
                    id = data(i).DefiningName;

                    if(data(i).Type == matlab.engine.internal.codegen.reporting.UnitType.Function)
                        sortedFunctionData = [sortedFunctionData data(i)];

                    else % Class or class member
                        if(m.isKey(id))
                            m(id) = [m(id) data(i)];
                        else
                            m(id) = data(i);
                        end
                    end
                end

                % Sort functions alphabetically
                if(~isempty(sortedFunctionData))
                    [~, ind] = sort([sortedFunctionData.DefiningName]);
                    sortedFunctionData = sortedFunctionData(ind);
                end

                % Sort class members alphabetically
                if(~isempty(m))
                    keys = m.keys;
                    for i = 1:length(keys)
                        temp = m(keys{i});
                        [~, ind] = sort([temp.Name]);
                        temp = temp(ind);
                        m(keys{i}) = temp;
                    end
                end

                sortedClassData = m;

                % Produce output string
                strOut = "";
                indent = "    ";
                classheader = string(message("MATLAB:engine_codegen:ClassesHeader").getString);
                functionheader = string(message("MATLAB:engine_codegen:FunctionsHeader").getString);

                if(~isempty(sortedClassData))
                    strOut = strOut + indent + classheader + newline;
                    keys = sortedClassData.keys;
                    for i = 1:length(keys)
                        classFamily = sortedClassData(keys{i});
                        className = classFamily(1).DefiningName;

                        strOut = strOut + indent + indent + className + ":";

                        % Was class itself listed? If so, no need to seach for members
                        if(sum([classFamily.Type] == matlab.engine.internal.codegen.reporting.UnitType.Class) > 0)
                            c = classFamily([classFamily.Type] == matlab.engine.internal.codegen.reporting.UnitType.Class);
                            strOut = strOut + " " + c(1).ReasonDropped + newline;
                            % Else search for properties and methods
                        else
                            strOut = strOut + newline;
                            props = classFamily([classFamily.Type] == matlab.engine.internal.codegen.reporting.UnitType.ClassProperty);
                            for p = props
                                strOut = strOut + indent + indent + indent + p.Name + ": " + p.ReasonDropped + newline;
                            end

                            meths = classFamily([classFamily.Type] == matlab.engine.internal.codegen.reporting.UnitType.ClassMethod);
                            for m = meths
                                strOut = strOut + indent + indent + indent + m.Name + ": " + m.ReasonDropped + newline;
                            end

                            enums = classFamily([classFamily.Type] == matlab.engine.internal.codegen.reporting.UnitType.EnumMember);
                            for e = enums
                                strOut = strOut + indent + indent + indent + e.Name + ": " + e.ReasonDropped + newline;
                            end

                        end


                    end
                end

                if(~isempty(sortedFunctionData))
                    strOut = strOut + indent + functionheader + newline;
                    for f = sortedFunctionData
                        strOut = strOut + indent + indent + f.DefiningName + ": " + f.ReasonDropped + newline;
                    end
                end

            end
        end

    end

end