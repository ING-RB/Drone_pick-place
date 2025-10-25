classdef GeneratedUnit
    %GeneratedUnit Represents a MATLAB code unit that has been generated
    %in a strongly-typed interface

    properties
        Type (1,1) matlab.engine.internal.codegen.reporting.UnitType
        Name (1,1) string
    end

    methods
        function obj = GeneratedUnit(type, name)
            arguments
                type (1,1) matlab.engine.internal.codegen.reporting.UnitType
                name (1,1) string
            end

            obj.Type = type;
            obj.Name = name;

        end

    end

    methods (Static)
        function strOut = dataToString(data)
            %dataToString used to print data on an array of "GeneratedUnit"s for use
            % in reporting printouts

            arguments
                data (1,:) matlab.engine.internal.codegen.reporting.GeneratedUnit
            end

            import matlab.engine.internal.codegen.reporting.UnitType

            strOut = "";

            if(~isempty(data))
                
                % Differentiate between classes and function data
                sortedClassData = data([data.Type] == UnitType.Class);
                sortedFunctionData = data([data.Type] == UnitType.Function);
                hasClassData = ~isempty(sortedClassData);
                hasFunctionData = ~isempty(sortedFunctionData);

                % Sort alphabetically
                if(hasClassData)
                    [~, ind] = sort([sortedClassData.Name]);
                    sortedClassData = sortedClassData(ind);
                end

                if(hasFunctionData)
                    [~, ind] = sort([sortedFunctionData.Name]);
                    sortedFunctionData = sortedFunctionData(ind);
                end

                % Produce output string
                strOut = "";
                indent = "    ";
                classheader = string(message("MATLAB:engine_codegen:ClassesHeader").getString);
                functionheader = string(message("MATLAB:engine_codegen:FunctionsHeader").getString);
                
                if(hasClassData)
                    strOut = strOut + indent + classheader + newline;
                    for c = sortedClassData
                        strOut = strOut + indent + indent + c.Name + newline;
                    end
                end

                if(hasFunctionData)
                    strOut = strOut + indent + functionheader + newline;
                    for f = sortedFunctionData
                        strOut = strOut + indent + indent + f.Name + newline;
                    end
                end

            end
        end
    end
end