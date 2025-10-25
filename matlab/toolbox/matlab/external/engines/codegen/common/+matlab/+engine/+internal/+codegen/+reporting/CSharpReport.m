classdef CSharpReport < matlab.engine.internal.codegen.reporting.ReportData
    % Handle writing out a report for C#

    methods
        function obj = saveReport(obj, filename, folderName, inputs)
            saveReport@matlab.engine.internal.codegen.reporting.ReportData(obj, ...
                filename, folderName, inputs);
        end

        function headerString = writeHeader(obj, targetFolder)
            headerString = "targetFolder: " + targetFolder + newline;
        end

        function functionHolderClassString = writeFunctionHolderClass(obj, functionHolderClass)
            functionHolderClassString = "FunctionHolderClass: " + functionHolderClass + newline;
        end

        function outerNamespaceString = writeOuterCSharpNamespace(obj, outerCSharpNamespace)
            outerNamespaceString = "OuterCSharpNamespace: " + outerCSharpNamespace + newline;
        end

        function checkErrorsWarnings(obj)
            %checkErrorsWarnings Checks for error or warning conditions
            % in recorded data

            % Error if there are dropped classes that were explicitly
            % specified to be generated

            if(~isempty(obj.Dropped))

                logindex = ~[obj.Dropped.IsImplicit];
                explicitDropped = obj.Dropped(logindex);
                if(~isempty(explicitDropped));
                    listDropped = newline + matlab.engine.internal.codegen.reporting.DroppedUnit.dataToString(explicitDropped);
                    messageObj = message("MATLAB:engine_codegen:SpecifiedItemNotGeneratedCSharp", listDropped);
                    error(messageObj);
                end

                % Warning if there are other dropped items
                implicitDropped = obj.Dropped(~logindex);
                if(~isempty(implicitDropped))
                    listDropped = newline + matlab.engine.internal.codegen.reporting.DroppedUnit.dataToString(implicitDropped);
                    messageObj = message("MATLAB:engine_codegen:ImplicitItemNotGeneratedCSharp", listDropped);
                    warning(messageObj);
                end

            end

            % Warning if there are missing dependencies
            if(~isempty(obj.Missing))
                messageObj = message("MATLAB:engine_codegen:GeneratorHasUnresolvedClassDependencies", join([obj.Missing.Name]));
                warning(messageObj);
            end

        end
    end
end