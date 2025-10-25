classdef VacantDataUnit
    %VacantDataUnit Represents a MATLAB code unit that is missing size or
    % type meta-data which could contribute useful information to the
    % strongly-typed interface

    properties
        Type (1,1) matlab.engine.internal.codegen.reporting.UnitType
        Name (1,1) string = ""
        VacantData (1,:) matlab.engine.internal.codegen.reporting.MetaUnit
    end

    methods (Static)
        function strOut = dataToString(data)
            %dataToString used to print data on an array of "VacantDataUnits"s for use
            % in reporting printouts
            arguments
                data (1, :) matlab.engine.internal.codegen.reporting.VacantDataUnit
            end

            import matlab.engine.internal.codegen.reporting.UnitType
            import matlab.engine.internal.codegen.reporting.MetaFieldType
            
            classData = [];
            functionData = [];

            % Separate classes and functions
            if(~isempty(data))
                classData = data([data.Type] == UnitType.Class);
                functionData = data([data.Type] == UnitType.Function);
            end
            hasClassData = ~isempty(classData);
            hasFunctionData = ~isempty(functionData);

            % Sort classes and functions alphabetically
            if(hasClassData)
                [~, ind] = sort([classData.Name]);
                classData = classData(ind);
            end
            if(hasFunctionData)
                [~, ind] = sort([functionData.Name]);
                functionData = functionData(ind);
            end
            
            % Produce output string
            strOut = "";
            indent = "    ";
            classheader = string(message("MATLAB:engine_codegen:ClassesHeader").getString);
            functionheader = string(message("MATLAB:engine_codegen:FunctionsHeader").getString);

            if(hasClassData)
                strOut = strOut + indent + classheader + newline;
                for c = classData;
                    % print class name
                    strOut = strOut + indent + indent + c.Name + ":" + newline;

                    % print prop info in alphabetical order
                    props = c.VacantData([c.VacantData.Type] == MetaFieldType.Property);
                    if(~isempty(props))
                        strOut = strOut + indent + indent + indent + string(message("MATLAB:engine_codegen:PropertiesHeader").getString) + newline;
                        [~, ind] = sort([props.StructureName]);
                        props = props(ind);
                        for p = props
                            temp = "";
                            if(~p.HasSize && p.HasType)
                                temp = string(message("MATLAB:engine_codegen:NoSize").getString);
                            end
                            if(~p.HasSize && ~p.HasType)
                                temp = string(message("MATLAB:engine_codegen:NoSizeOrType").getString);
                            end
                            if(p.HasSize && ~p.HasType)
                                temp = string(message("MATLAB:engine_codegen:NoType").getString);
                            end
                            strOut = strOut + indent + indent + indent + indent + p.Name + ": " + temp + newline;
                        end
                    end

                    % print method info
                    inputMeths = c.VacantData([c.VacantData.Type] == MetaFieldType.MethodInputArgument);
                    outputMeths = c.VacantData([c.VacantData.Type] == MetaFieldType.MethodOutputArgument);
                    meths = [inputMeths, outputMeths]; % print inputs before outputs
                    if(~isempty(meths))
                        strOut = strOut + indent + indent + indent + string(message("MATLAB:engine_codegen:MethodsHeader").getString) + newline;
                        methodNames = string.empty(1,0);
                        argType = "Input"; % keep track that we are printing input args with missing data
                        for i = 1:length(meths)
                            m = meths(i);
                            if(i == length(inputMeths)+1)
                                argType = "Output"; % switch to printing output args
                            end

                            % If method is new, show it
                            if(~ismember(m.StructureName, methodNames))
                                methodNames = [methodNames m.StructureName];
                                strOut = strOut + indent + indent + indent +indent + m.StructureName + ":" + newline;
                            end
                            temp = "";
                            if(~m.HasSize && m.HasType)
                                temp = string(message("MATLAB:engine_codegen:" + argType + "ArgNoSize").getString);
                            end
                            if(~m.HasSize && ~m.HasType)
                                temp = string(message("MATLAB:engine_codegen:" + argType + "ArgNoSizeOrType").getString);
                            end
                            if(m.HasSize && ~m.HasType)
                                temp = string(message("MATLAB:engine_codegen:" + argType + "ArgNoType").getString);
                            end
                            strOut = strOut + indent + indent + indent + indent + indent + m.Name + ": " + temp + newline;
                        end

                    end
                end
            end

            if(hasFunctionData)
                strOut = strOut + indent + functionheader + newline;
                

                for f = functionData
                    functionNames = string.empty(1,0);

                    inputArgs = f.VacantData([f.VacantData.Type] == MetaFieldType.FunctionInputArgument);
                    outputArgs = f.VacantData([f.VacantData.Type] == MetaFieldType.FunctionOutputArgument);

                    vacantFuncItems = [inputArgs, outputArgs]; % Print the input arguments, then the output arguments
                    argType = "Input";

                    for i = 1:length(vacantFuncItems)

                        v = vacantFuncItems(i);

                        % If function is new, show it
                        if(~ismember(v.StructureName, functionNames))
                            functionNames = [functionNames v.StructureName];
                            strOut = strOut + indent + indent  + v.StructureName + ":" + newline;
                        end

                        if(i == length(inputArgs)+1)
                            argType = "Output"; % switch to printing output args
                        end

                        temp = "";
                        if(~v.HasSize && v.HasType)
                            temp = string(message("MATLAB:engine_codegen:" + argType + "ArgNoSize").getString);
                        end
                        if(~v.HasSize && ~v.HasType)
                            temp = string(message("MATLAB:engine_codegen:" + argType + "ArgNoSizeOrType").getString);
                        end
                        if(v.HasSize && ~v.HasType)
                            temp = string(message("MATLAB:engine_codegen:" + argType + "ArgNoType").getString);
                        end
                        strOut = strOut + indent + indent + indent + v.Name + ": " + temp + newline;
                    end

                end
            end
        end
    end

end