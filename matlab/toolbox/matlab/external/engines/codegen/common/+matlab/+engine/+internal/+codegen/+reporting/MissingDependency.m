classdef MissingDependency
    %MissingDependency Represents a missing MATLAB class which should
    %be included in the strongly-typed interface to resolve dependencies

    properties
        Type (1,1) matlab.engine.internal.codegen.reporting.UnitType = matlab.engine.internal.codegen.reporting.UnitType.Class
        DefiningName (1,1) string
        Name (1,1) string
        Dependants (1,:) string  % things that depend on missing unit
    end

    methods

        function obj = MissingDependency(name, dependants)
            arguments
                name (1,1) string
                dependants (1,:) string
            end
            obj.DefiningName = name;
            obj.Name = name;
            obj.Dependants = dependants;
        end

    end

    methods (Static)
        function strOut = dataToString(data)
            %dataToString used to print data on an array of "MissingDependency"s for use
            % warning messages and in reporting printouts

            arguments
                data (1,:) matlab.engine.internal.codegen.reporting.MissingDependency
            end

            import matlab.engine.internal.codegen.reporting.UnitType

            strOut = "";

            hasClassData = ~isempty(data);

            if(~isempty(data))

                % Sort alphabetically
                if(hasClassData)
                    [~, ind] = sort([data.Name]);
                    sortedClassData = data(ind);
                end

                % Produce output string
                strOut = "";
                indent = "    ";

                for c = sortedClassData
                    strOut = strOut + indent + c.Name + " " + string(message("MATLAB:engine_codegen:HasDependants").getString) + " " + strjoin(c.Dependants, ", ") + newline;
                end

            end
        end
    end

end

