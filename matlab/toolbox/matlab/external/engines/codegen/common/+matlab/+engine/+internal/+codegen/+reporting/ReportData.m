classdef ReportData < handle
    %ReportData An instance of this class handles reporting to the end user
    % what has been generated in the strongly typed interface and what was
    % ommitted from the interface and why if neccesary
    
    %   Copyright 2021-2023 The MathWorks, Inc.

    properties
        Generated    matlab.engine.internal.codegen.reporting.GeneratedUnit     = matlab.engine.internal.codegen.reporting.GeneratedUnit.empty()
        Dropped      matlab.engine.internal.codegen.reporting.DroppedUnit       = matlab.engine.internal.codegen.reporting.DroppedUnit.empty()
        VacantMeta   matlab.engine.internal.codegen.reporting.VacantDataUnit    = matlab.engine.internal.codegen.reporting.VacantDataUnit.empty()
        Missing      matlab.engine.internal.codegen.reporting.MissingDependency = matlab.engine.internal.codegen.reporting.MissingDependency.empty()
    end

    properties(Access=private)
        ReportContents (1,1) string = "";
    end

    methods

        function displayReport(obj, headerName, inputs)
            %displayReport Displays the main report to the MATLAB command
            % window

            % Leading newline for readability
            disp(newline + obj.prepareReport(headerName, inputs));
            
        end

        function saveReport(obj, filename, headerName, inputs)
            %saveReport Saves the main report to the specified file

            % Get report body
            report = obj.prepareReport(headerName, inputs);

            % End with 2 newlines in case of appending workflow
            report = report + newline + newline;

            wh = fopen(filename, 'a+');
            if wh >= 3
                fprintf(wh, '%s', report); % %s to prevent possible \ escape char
            else
                messageObj = message("MATLAB:engine_codegen:ReportWriteError", filename);
                error(messageObj);
            end
            fclose(wh);
        end

        function strOut = prepareReport(obj, headerName, inputs)
            %prepareReport Given previously recorded data, a report is
            %generated in text format using message catalog localisation

            % headername - name of output headerfile
            % inputs - Input name-value pairs supplied in user-facing
            % function

            import matlab.engine.internal.codegen.reporting.*
            strOut = "";
            indent = "    ";

            % Display general information first
            d = datetime;
            workingDir = string(pwd);
            strOut = string(message("MATLAB:engine_codegen:GeneralInfo").getString) + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:Date").getString) + " " + string(d) + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:WorkingDir").getString) + " " + workingDir + newline;

            % Print information on supplied inputs
            strOut = strOut + newline + string(message("MATLAB:engine_codegen:InputsHeader").getString) + newline;
            strOut = strOut + indent + obj.writeHeader(headerName);
            % write out C# values, check for C# specific name-value pairs.  They are
            % NOT defined in C++.
            if isfield(inputs, "FunctionHolderClass")
                strOut = strOut + indent + obj.writeFunctionHolderClass(inputs.FunctionHolderClass);
            end
            if isfield(inputs, "OuterCSharpNamespace")
                strOut = strOut + indent + obj.writeOuterCSharpNamespace(inputs.OuterCSharpNamespace);
            end

            if(~isempty(inputs.Packages))
                strOut = strOut + indent + string(message("MATLAB:engine_codegen:PackagesHeader").getString) + newline;
                for p = inputs.Packages
                    strOut = strOut + indent + indent + p + newline;
                end
            end

            if(~isempty(inputs.Classes))
                strOut = strOut + indent + string(message("MATLAB:engine_codegen:ClassesHeader").getString) + newline;
                for c = inputs.Classes
                    strOut = strOut + indent +indent + c + newline;
                end
            end

            if(~isempty(inputs.Functions))
                strOut = strOut + indent + string(message("MATLAB:engine_codegen:FunctionsHeader").getString) + newline;
                for f = inputs.Functions
                    strOut = strOut + indent +indent + f + newline;
                end
            end

            if(inputs.DisplayReport == true)
                strOut = strOut + indent + "DisplayReport: " + string(message("MATLAB:engine_codegen:true").getString) + newline;
            elseif(inputs.DisplayReport == false)
                strOut = strOut + indent + "DisplayReport: " + string(message("MATLAB:engine_codegen:false").getString) + newline;
            end

            if(inputs.SaveReport == "" || isempty(inputs.SaveReport))
                strOut = strOut + indent + "SaveReport: " + string(message("MATLAB:engine_codegen:NoReportOutputFile").getString) + newline;
            else
                strOut = strOut + indent + "SaveReport: " + string(inputs.SaveReport) + newline;
            end

            
            % Print information on generated items to string
            if(~isempty(obj.Generated))
                genSectionContent = GeneratedUnit.dataToString(obj.Generated);
                strOut = strOut + newline + string(message("MATLAB:engine_codegen:GeneratedItemsHeader").getString) + newline;
                strOut = strOut + genSectionContent;
            end

            % Print information on omitted items to string
            if(~isempty(obj.Dropped))
                droppedSectionContent = DroppedUnit.dataToString(obj.Dropped);
                strOut = strOut + newline + string(message("MATLAB:engine_codegen:OmittedItemsHeader").getString) + newline;
                strOut = strOut + droppedSectionContent;
            end

            % Print information on any missing class dependencies to string
            if(~isempty(obj.Missing))
                missingSectionContent = MissingDependency.dataToString(obj.Missing);
                strOut = strOut + newline + string(message("MATLAB:engine_codegen:MissingClassesHeader").getString) + newline;
                strOut = strOut + missingSectionContent;
            end

            % Print information on vacant data
            if(~isempty(obj.VacantMeta))
                vacantSectionContent = VacantDataUnit.dataToString(obj.VacantMeta);
                strOut = strOut + newline + string(message("MATLAB:engine_codegen:VacantValidationHeader").getString) + newline;
                strOut = strOut + vacantSectionContent;
            end

            % Calculate important summary values
            numGenClass = sum([obj.Generated.Type] == UnitType.Class);
            numGenFunction = sum([obj.Generated.Type] == UnitType.Function);
            numDroppedClass = sum([obj.Dropped.Type] == UnitType.Class);
            numDroppedProp = sum([obj.Dropped.Type] == UnitType.ClassProperty);
            numDroppedMeth = sum([obj.Dropped.Type] == UnitType.ClassMethod);
            numDroppedFunc = sum([obj.Dropped.Type] == UnitType.Function);
            numMissingClass = length(obj.Missing);
            numItemsVacantData = 0;
            for v = obj.VacantMeta
                numItemsVacantData = numItemsVacantData + length(v.VacantData);
            end

            % Print concluding summary to string
            strOut = strOut + newline + string(message("MATLAB:engine_codegen:SummaryHeader").getString) + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumClass").getString) + " " + numGenClass + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumFunc").getString) + " " + numGenFunction + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumOmittedClass").getString) + " " + numDroppedClass + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumOmittedProp").getString) + " " + numDroppedProp + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumOmittedMeth").getString) + " " + numDroppedMeth + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumOmittedFunc").getString) + " " + numDroppedFunc + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumMissingClass").getString) + " " + numMissingClass + newline;
            strOut = strOut + string(message("MATLAB:engine_codegen:SummaryNumVacantData").getString) + " " + numItemsVacantData;
        end

        function displayBriefGenerationReport(obj, filename)
            %displayBriefGenerationReport Displays a stand-alone one-line
            % summary of what classes and functions were written to file
            if filename == "."
                filename = pwd;
            elseif filename == ".."
                filename = fileparts(pwd);
            end
            numClass = sum([obj.Generated.Type] == matlab.engine.internal.codegen.reporting.UnitType.Class);
            numFunction = sum([obj.Generated.Type] == matlab.engine.internal.codegen.reporting.UnitType.Function);
            messageObj = message("MATLAB:engine_codegen:BriefGenerationReport", numClass, numFunction, filename);
            disp(messageObj.getString)

        end

        function recordGenerated(obj, type, generatedItems)
            %recordGenerated Records a group of generated items in the
            % report object
            arguments
                obj (1,1) matlab.engine.internal.codegen.reporting.ReportData
                type (1,1) matlab.engine.internal.codegen.reporting.UnitType
                generatedItems (1,:) {mustBeA(generatedItems, ...
                    ["matlab.engine.internal.codegen.ClassTpl", ...
                    "matlab.engine.internal.codegen.FunctionTpl"])}
            end

            names = [generatedItems.FullName];
            generated = [];
            for n = names
                generated = [generated matlab.engine.internal.codegen.reporting.GeneratedUnit(type, n)];
            end

            obj.Generated = [obj.Generated generated];

        end

        function recordDropped(obj, type, droppedItems, reason, omitWarning)
            %recordDropped Records a group of dropped items in the report
            % object

            arguments
                obj (1,1) matlab.engine.internal.codegen.reporting.ReportData
                type (1,1) matlab.engine.internal.codegen.reporting.UnitType
                droppedItems (1,:) {mustBeA(droppedItems, ...
                    ["matlab.engine.internal.codegen.ClassTpl", ...
                    "matlab.engine.internal.codegen.PropertyTpl" ...
                    "matlab.engine.internal.codegen.MethodTpl" ...
                    "matlab.engine.internal.codegen.FunctionTpl" ...
                    "meta.EnumeratedValue"])}
                reason (1,1) message
                omitWarning (1,1) logical = false % Option to omit a dropped unit from being in a warning message (set to true to omit)
            end

            % Assumes droppedItems are unique. Ensuring unique-ness should be handled elsewhere
            import matlab.engine.internal.codegen.reporting.UnitType;
            dropped = [];

            if(type == UnitType.ClassMethod || type == UnitType.ClassProperty)
                selfNames = [droppedItems.SectionName]; % name of the methods or properties
                encapsulatingNames = [droppedItems.EncapsulatingClass]; % name of the most-derived class which has the method or property as a member
                isImplicit = droppedItems.IsImplicit;
            elseif(type == UnitType.EnumMember)
                selfNames = string({droppedItems.Name});
                encapsulatingNames = string({droppedItems.DefiningClass.Name});
                isImplicit = ones(1, length(droppedItems));
            else % is Class or function
                selfNames = [droppedItems.SectionName];
                encapsulatingNames = [droppedItems.FullName];
                isImplicit = droppedItems.IsImplicit; % whether user specifically specified the item to be generated, or was implicitly specified
            end

            for i = 1:length(droppedItems)
                dropped = [dropped matlab.engine.internal.codegen.reporting.DroppedUnit(type, encapsulatingNames(i), selfNames(i), reason, isImplicit, omitWarning)];
            end
            obj.Dropped = [obj.Dropped dropped];

        end

        function recordMissing(obj, type, missingItems, dependants)
            %recordMissing Records a group of missing items in the report
            % object

            arguments
                obj (1,1) matlab.engine.internal.codegen.reporting.ReportData
                type (1,1) matlab.engine.internal.codegen.reporting.UnitType
                missingItems (1,:) string
                dependants (1, :) cell
            end

            names = [missingItems.FullName];
            names = unique(names);
            missing = [];
            for n = names
                missing = [missing matlab.engine.internal.codegen.reporting.MissingDependency(type, n, reason)];
            end
            obj.Dropped = [obj.Dropped missing];

        end

        function recordVacant(obj, type, name, metaUnits)
            arguments
                obj  (1,1)
                type matlab.engine.internal.codegen.reporting.UnitType % The code unit being generated
                name (1,1) string % Name of unit being generated
                metaUnits (1,:) matlab.engine.internal.codegen.reporting.MetaUnit % sub units which have missing meta-data
            end

            v = matlab.engine.internal.codegen.reporting.VacantDataUnit();
            v.Type = type;
            v.Name = name;
            v.VacantData = metaUnits;

            obj.VacantMeta = [obj.VacantMeta v];

        end

        function checkErrorsWarnings(obj)
            %checkErrorsWarnings Checks for error or warning conditions
            % in recorded data

            % Error if there are dropped classes that were explicitly
            % specified to be generated

            if(~isempty(obj.Dropped))

                explicitIndex = ~[obj.Dropped.IsImplicit];
                explicitDropped = obj.Dropped(explicitIndex);
                if(~isempty(explicitDropped));
                    listDropped = newline + matlab.engine.internal.codegen.reporting.DroppedUnit.dataToString(explicitDropped);
                    messageObj = message("MATLAB:engine_codegen:SpecifiedItemNotGenerated", listDropped);
                    error(messageObj);
                end

                % Warning if there are other dropped items.
                % Don't warn about item if OmitWarning is specified
                omitWarningIndex = [obj.Dropped.OmitWarning];
                warningIndex = ~explicitIndex & ~omitWarningIndex; % if not explicit and not omitted, then warn
                warningDropped = obj.Dropped(warningIndex);
                
                if(~isempty(warningDropped))
                    listDropped = newline + matlab.engine.internal.codegen.reporting.DroppedUnit.dataToString(warningDropped);
                    messageObj = message("MATLAB:engine_codegen:ImplicitItemNotGenerated", listDropped);
                    warning(messageObj);
                end

            end

            % Warning if there are missing dependencies
            if(~isempty(obj.Missing))
                messageObj = message("MATLAB:engine_codegen:GeneratorHasUnresolvedClassDependencies", join([obj.Missing.Name]));
                warning(messageObj);
            end

        end

        function headerString = writeHeader(obj, headerName)
            headerString = "headerName: " + headerName + newline; % headerName matches arg name in generateCPP
        end

        % return nothing for C++
        function functionHolderClassString = writeFunctionHolderClass(obj, functionHolderClass)
            functionHolderClassString = "";
        end
        
        % return nothing for C++
        function outerNamespaceString = writeOuterCSharpNamespace(obj, outerCSharpNamespace)
            outerNamespaceString = "";
        end

    end


end

