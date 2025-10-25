classdef PlotsTabUtils
    % A utility class for the MATLAB On The Web Plots Tab. This class handles 
    % selection change events and gets a list of all plots from PlotsMap that 
    % are valid for the current selection and sends to the client.
    % On plot execution, this class generates the correct execution string
    % and evaluates as well as publishes the code generated. 
    % During execution, it also generates titles and labels for supported
    % plots.
    
    % Copyright 2013-2025 The MathWorks, Inc.
    
    methods(Static = true, Access = 'protected')
        % Move the methods that call the Java Classes here so they can be
        % overridden in the Test Class
        
        function result = getSelectionNames(var, selectionString, isObj)
            arguments
                var
                selectionString
                isObj = false
            end
            if (isstruct(var) || isObj || istabular(var) || isa(var, "dataset"))
                result = strsplit(selectionString,';');
            else
                result{1} = selectionString;
            end
        end
        
        function map = getPlotsMap()
            adaptor = internal.matlab.plotstab.PlotsTabAdapter.getInstance();
            map = adaptor.getPlotsMap();
        end
        
        function outputString = getCamelCase(tag)
            spaces = find(tag==' ');
            tag(spaces+1) = upper(tag(spaces+1));
            tag(tag==' ') = [];
            outputString = tag;
        end
        
        function outputTag = getFormattedTag(itemTag)
            itemTag = internal.matlab.plotstab.PlotsTabUtils.getCamelCase(itemTag);
            % if the tag name has a '.' in it we change it to '_'. This is done because
            % tag names are used as file names to uniquely identify plots.
            itemTag = strrep(itemTag,'.','_');
            outputTag = strcat('plots_',char(itemTag));
        end
        
        % The client expects a 'selectionChanged' So the server eventtype strings are
        % translated to match the event strings expected by the client
        % 'selectionChanged'       <- (selectionChanged,
        %                              variablesSwapped,
        %                              DataChange
        %                              DocumentFocusGained
        %                              ManagerFocusGained)
        function translatedEvntType = translateEvntTypeString(eventType)
            translatedEvntType = '';
            if strcmp(eventType,'SelectionChanged') || strcmp(eventType,'variablesSwapped') ||...
                    strcmp(eventType,'DataChange') || strcmp(eventType,'DocumentFocusGained') || ...
                    strcmp(eventType, 'ManagerFocusGained') || strcmp(eventType, 'DocumentTypeChanged') || ...
                    strcmp(eventType, 'ManagerFocusChanged')
                translatedEvntType = 'selectionChanged';
            end
        end
        
        % swap function specifically for a cell array of length 2
        function swappedResult = swap(selection)
            temp = selection{1};
            selection{1} = selection{2};
            selection{2} = temp;
            swappedResult = selection;
        end
        
        % Return the classType as sparse for sparse variables as class(data)
        % returns double instead of sparse.
        function classType = getClassType(data)
            if issparse(data)
                classType='sparse';
            else
                classType = class(data);
            end
        end
        
        % Checks and returns if a particular plot action is enabled for a given selection combination
        % Takes in the Plot item that has id and optionally a selectionCode
        % Selection is a cellstr with selected variable names.
        function isEnabled = isValidPlotForSelection(selectedItem, selection)
            L = lasterror; %#ok<*LERR>
            isEnabled = false;
            % if the product is installed but the user does not
            % have a license, the items returns will be empty
            % so we should ignore them
            if isempty(selectedItem)
                return;
            end
            try
                if isempty(selectedItem.selectionCode)
                    isEnabled = plotpickerfunc('defaultshow',selectedItem.id,{},selection);
                else
                    selectionMcodeHandle = eval(selectedItem.selectionCode);
                    isEnabled = feval(selectionMcodeHandle, selection);
                end
            catch
                % Catch any errors to protect against toolboxes which might potentially
                % involve errors while evaluating Plot Actions
                
                % If any of the variables are tall, reset lasterror
                if any(cellfun(@(x) istall(x), selection))
                    lasterror(L);
                end
            end 
        end
        
        % Returns true if the plot has a custom execution function
        % (Indicated by hasCustomFcn)
        function result = hasCustomExecutionFunction(plotType)
            result = plotType.hasCustomFcn;    
        end
        
        % Returns the custom execution function(most commonly a call to
        % plotpickerfunc) along with a cellstr of selected varnames.
        function result = getCustomExecutionFunction(plotType, selectionNames)
        
            import internal.matlab.plotstab.PlotsTabUtils.*;

            execFunc = plotType.customExeFcn;
            
            if (getAnonymousInputCount(execFunc)==1)
                result = "feval(" + execFunc + "," + getArgumentStringCellArray(selectionNames) + ")";
            else
                result = "feval(" + execFunc + "," + getArgumentStringCellArray(selectionNames) + ...
                                   "," + getArgumentCellArray(selectionNames) + ")";        
            end
        end
        
        function commaCount = getAnonymousInputCount(funcstring)

            commaCount = 0;
            if isempty(funcstring) %|| isempty(regexp(funcstring, "^@\\(.+\\).+", 'ONCE'))
                return;
            end
            
            % Get the section of the string that indicates the input args
            openParen = strfind(funcstring, '(');
            closeParen = strfind(funcstring, ')');
            
            % If I don't find parens in this string, return
            if isempty(openParen) || isempty(closeParen)
                return;
            end
            
            argStr = convertStringsToChars(funcstring);
            
            % Get the chars between the first open and close paren
            argStr = argStr(openParen(1):closeParen(1));
            
            % There is always one more input than commas
            commaCount = numel(strfind(argStr, ',')) + 1;
        end
        
        function argString = getArgumentStringCellArray(selectedVars)
        
            argString = "{'";        
            argString = argString.append(selectedVars{1});

            for j = 2:numel(selectedVars)
                item = selectedVars{j};
                argString = argString.append("','");
                argString = argString.append(item);
            end

            argString = argString.append("'}");
        end        
        
        function argString = getArgumentCellArray(selectedVars)
        
            var = string(selectedVars{1});
        
            if length(selectedVars) == 1 && ~isempty(regexp(var, "^cell2mat\\s*\\(.*\\)", 'ONCE'))
                varName = regexprep(var, "^cell2mat\\s*\\(", "");
                varName = regexprep(varName, "\\)$", "");
                argString =  "internal.matlab.plotpicker.inputPreProc('cell2mat',{" +varName+"})";
            else
                argString = "";
                argString = argString.append("{");
                argString = argString.append(var);
                
                for j = 2:numel(selectedVars)
                    argString = argString.append(",");
                    argString = argString.append(selectedVars{j});
                end

                argString = argString.append( "}");
            end
        end
        
        % Creates execution string for plots that do not have a custom
        % execution function. Data-linking mode could be turned on,
        % generate X|Y|X datasource codegen accordingly.
        function argString = createArgumentString(selectionNames, plotName) 
            arguments
                selectionNames = {}
                plotName = ''
            end
            argString = "";
            linkCode = '';
            % List of 2d && 3d Plots that support data linking.
            %TODO: In the future, use upstream APIs to detect whether a
            %plot supports data linking or not. Currently, this is hard
            %coded in generation syntax here and in plotpickerfunc(for
            %plots that have custom exec function)
            supportsLinking =  any(strcmp(plotName,["errorbar","polarplot", "polarscatter", "polarbubblechart"]));
            supports3dLinking = any (strcmp(plotName, ["plot3", "stem3", "scatter3"]));
            pt = internal.matlab.plotstab.PlotsTabState.getInstance();
            if (pt.AutoLinkData && (supportsLinking || supports3dLinking))
                n = length(selectionNames);
                if supports3dLinking && n > 2
                    linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s'',ZDataSource=''%s''',selectionNames{1}, selectionNames{2}, selectionNames{3});
                elseif (n > 1)
                    linkCode = sprintf(',XDataSource = ''%s'',YDataSource = ''%s''', selectionNames{1}, selectionNames{2});
                elseif n==1
                    linkCode = sprintf(',YDataSource = ''%s''', selectionNames{1});
                end
            end
            if ~isempty(selectionNames)

                if numel(selectionNames) == 1
                    argString = "(" + selectionNames{1} + linkCode + ")";
                else                
                    argString = argString.append("(");
                    argString = argString.append(selectionNames{1});

                    for k = 2:numel(selectionNames)
                        item = selectionNames(k);
                        argString = argString.append(",");
                        argString = argString.append(item);
                    end
                    argString = argString.append(linkCode).append(")");            
                end            
            end
        end
        
        function result = getExecutionFunction(plotItem, selectionNames)
            import internal.matlab.plotstab.PlotsTabUtils.*;
            result = plotItem.evalFcn + createArgumentString(selectionNames, plotItem.id) + ";";            
        end
        
        % Generates codegen for the given plotType and selectionNames as {}.
        function [execString, doEval] = getEvalString(plotType, selectionNames)
            doEval = false;    
            if internal.matlab.plotstab.PlotsTabUtils.hasCustomExecutionFunction(plotType)
                execString = internal.matlab.plotstab.PlotsTabUtils.getCustomExecutionFunction(plotType, selectionNames);
                doEval = true;
            else
                % if the plot does not have a custom execution string then get the default
                % execution string
                execString = internal.matlab.plotstab.PlotsTabUtils.getExecutionFunction(plotType, selectionNames);
            end
        end

        % If Data linking is on, execString will contain DataSource
        % codegen. Generate linkdata on to turn on data linking.
        function linkDataStr = getLinkDataString(execString, ~, ~)
            % If this is a plot for which we support linking
            linkDataStr = string.empty;
            if contains(execString, 'YDataSource')
                linkDataStr = "linkdata on;";                               
            end
        end

        % For given selectionNames, generate title for the plot.
        % TODO: Check if plotType supports title
        function titleStr = getTitleString(axes, plotType, selectionNames, name)     
            len = length(selectionNames);
            if len == 1
                titleStr = selectionNames{1};
            elseif len == 2
                titleStr = selectionNames{2} + " vs " + selectionNames{1};
            else
                titleStr = name;
            end
            titleStr = "title(""" + titleStr + """);";
        end

        % For given selectionNames, generate X|Y|Z labels on the plot.
        % In addition to generating labels, also check whether the label
        % type being generated (X|Y|Z) exists in supportedFeatures given to
        % us by the MetaDataService for the current axes. 
        % For e.g wordcloud chart does not support labels and legends.
        function labelsStr = getLabelsString(axes, plotType, selectionNames, supportedFeatures)
            len = length(selectionNames);
            labelsStr = string.empty;
            % Histogram plots xData, so generate xLabel instead. 
            % NOTE: The right labels based on plot type are requirements
            % for the metadataservice, speacial case this use-case for now.
            if strcmp(plotType, 'histogram') && supportedFeatures.YLabel 
                labelsStr = "xlabel("""+ selectionNames{1} + """);";
            elseif (len == 1 || any(strcmp(plotType, ["plot_multiseries","plot_multiseriesfirst"]))) && supportedFeatures.YLabel
                labelsStr = "ylabel("""+ strjoin(selectionNames, ',') + """);";
            elseif (len > 1 && is2D(axes)) && supportedFeatures.XLabel && supportedFeatures.YLabel
                labelsStr = "xlabel("""+ selectionNames{1} + """);" + newline + "ylabel(""" + selectionNames{2} + """);";    
            elseif supportedFeatures.XLabel && supportedFeatures.YLabel && supportedFeatures.ZLabel
                labelsStr = "xlabel("""+ selectionNames{1} + """);" + newline + "ylabel(""" + selectionNames{2} + """);" + newline + "zlabel(""" + selectionNames{3} +""");";  
            end
        end

        % For given plot, generate legend code.
        % TODO: Check if plotType supports legends
        function legendStr = getLegendString(axes, ~, ~)
            legendStr = "legend(""show"");"; 
        end

         % Returns the label names to be displayed as labels and title on the figure. 
         function labelNames = getLabelNamesFromSelection(selectionNames, varName)
             labelNames = selectionNames;
             variable = evalin("debug", varName);
             varNames = [];
             if istimetable(variable)
                 varNames = [variable.Properties.DimensionNames{1}, variable.Properties.VariableNames];
             elseif istabular(variable)
                 varNames = variable.Properties.VariableNames;
             elseif isa(variable, "dataset")
                 varNames = variable.Properties.VarNames;
             end

             if ~isempty(varNames)
                 % selection names will be prefixed with tablename, remove
                 % those. (t.Age will be 'Age')
                labelNames = erase(labelNames, varName+".");

                for i=1:length(labelNames)
                    name = labelNames{i};
                    if ~isvarname(name)
                        if startsWith(name, '(')
                            % Arbitrary variable names will be passed in as
                            % t.(2), extract column indices and get the
                            % corresponding VariableName that is displayed.
                            varIndex = extractBetween(name, '(', ')');
                            trimmedName = replace(name, ['(' varIndex{1} ')'], '');
                            varIndex = str2double(varIndex(1));
                            % If there is a sub-selection, retain those indices
                            if istimetable(variable)
                                varIndex = varIndex + 1;
                            end
                            labelNames{i} = [varNames{varIndex} trimmedName];
                        elseif startsWith(name, "Properties.RowTimes")
                            % Special case for timetables where RowTimes
                            % dimension name contains non-printing
                            % characters
                            labelNames{i} = strrep(name, 'Properties.RowTimes', varNames{1});
                        end
                    end
                end
                labelNames = strrep(labelNames, newline, matlab.internal.display.getNewlineCharacter(newline));
             end
        end
    end
    
    methods(Static = true)
        
        function selNames = getSelectionVarNamesForVariableEditor(selectionString, document)
            selNames = {};           
            if ~isempty(document)
                isObj = isa(document.ViewModel, 'internal.matlab.variableeditor.ObjectViewModel') || ...
                    isa(document.ViewModel, 'internal.matlab.variableeditor.ObjectArrayViewModel');
                selNames = internal.matlab.plotstab.PlotsTabUtils.getSelectionNames(document.DataModel.Data, selectionString, isObj);
            end
        end

        % Handles selection updates to which the plots gallery has to react. Uses the input selection
        % data to construct and publish to client an object, representing the plot items to be
        % displayed and their corresponding execution strings.
        % Format of published data object is
        % data.variables = <array of selected variables>,
        % data.items = <array of supported plot strings>: ['plot','area','bar',...]
        % data.isPrivateWorkspace = <To be used on execution>
        % data.selectionSrc ['variables'| 'workspace'] indicating the source.
        function publishData = handleSelection(selection, selectionNames, eventType, isPrivateWorkspace, selectionSrc)
            arguments
                selection
                selectionNames
                eventType
                isPrivateWorkspace = false
                selectionSrc = ''
            end
            eventTypeToPublish = internal.matlab.plotstab.PlotsTabUtils.translateEvntTypeString(eventType);
            publishData = struct('eventType',char(eventTypeToPublish));
            publishData.selectionSrc = selectionSrc; 
            publishData.isPrivateWorkspace = isPrivateWorkspace;
            len = length(selectionNames);
            % cell array of selected variables
            varsSelectedArray = cell(1, len);
            if ~isempty(selectionNames)
                for v=1:len
                    dataClass = internal.matlab.plotstab.PlotsTabUtils.getClassType(selection{v});
                    varsSelectedArray{v} = struct('text',selectionNames{v},'type',dataClass);
                end
            end
            items = [];           
            % Evaluates the plots that are valid for the given selection
            % and the result of selected plots is a cellstr(items)
            if ~isempty(selectionNames)  
                    w = warning('off', 'all');
                    c = onCleanup(@() warning(w));
                    naninfBreakpoint = internal.matlab.datatoolsservices.DebugUtils.disableNanInfBreakpoint();
                    c2 = onCleanup(@() internal.matlab.datatoolsservices.DebugUtils.reEnableNanInfBreakpoint(naninfBreakpoint));

                    % map is a map of <string, struct>
                    map = internal.matlab.plotstab.PlotsTabUtils.getPlotsMap();
                    keys = map.keys;
                    validPlotIndices = cellfun(@(x)internal.matlab.plotstab.PlotsTabUtils.isValidPlotForSelection(x, selection),values(map));
                    items = keys(validPlotIndices);
            end
            publishData.items = items;
            publishData.variables = varsSelectedArray;
            % Publish data to client containing list of valid plots.
            message.publish('/PlotsChannel', publishData);
        end

        % Deals with generating and executing code for the given plotName.
        % plotName: string containing the name of the plot for which
        % executionString is to be generated. 
        % selectionNames is an array of the selected variable names
        % varName: name of the workspace variable being plotted. 
        % isPrivateWorkspace:logical indicating true if the variable is in a private workspace.
        % actionType: Could be "execute"|"show". If Execute, code is generated and executed on the command window. 
        %             If "show", code is just displayed on the command window with blinking cursor. 
        % plotSettingRoot: settings root from which the plot generation options are queried passed in from PlotsTabListeners. 
        % (The sources could be VariableEditor or WorkspaceBrowser, plotSettingRoot will be passed in accordingly).
        function handleExecution(plotName, selectionNames, varName, isPrivateWorkspace, actionType, plotSettingRoot)
            arguments
                plotName
                selectionNames
                varName string
                isPrivateWorkspace = false
                actionType = "execute"
                plotSettingRoot = settings;
            end

            % Nothing to execute for private workspaces, early return.
            if isPrivateWorkspace
                return;
            end
            % Get the plot entry from PlotsMap (Our Model) and compute eval
            % string.
            map = internal.matlab.plotstab.PlotsTabUtils.getPlotsMap();
            plotEntry = map(plotName);
            [execString, doEval] = internal.matlab.plotstab.PlotsTabUtils.getEvalString(plotEntry,...
                selectionNames);

            if doEval
                execString = evalin('debug', execString);                             
            end
            % Generate execString as-is or with figure; based on the figure creation plot options.
            newFigureOption = false;
            % Allow new figure operation for non-GUI environment
            if ~plotEntry.isGUI
                s = settings;
                % True indicates reuse figure and false indicates new figure.
                newFigureOption = ~s.matlab.desktop.toolstrip.plotsgallery.NewFigurePlotOption.ActiveValue;
            end
            if newFigureOption
                % Generate figure; syntax for new figures
                execString = strcat('figure;',sprintf("\n"),execString);
            end
            if ~isempty(execString)
                % Some plots do not end with ';', need to standardize
                % codegen.
                if ~(endsWith(execString, ';'))
                    execString = strcat(execString, ';');
                end
                % If the request was to show at command window, just print and exit
                if strcmp(actionType, "show")
                    internal.matlab.desktop.commandwindow.showCommand(execString);
                    return;
                end
                % Evaluate the plot generation code in order to get a handle to axes. 
                % The axes will help determine if any of the titles and labels generation is valid for the current plot.
                evalin('debug', execString);
                f = gcf;
                if plotSettingRoot.DockFigure.ActiveValue
                    f.WindowStyle = "docked";
                else
                    f.WindowStyle = "normal";
                end

                % If we have the focus figure button selected then we want
                % to focus the figure here
                % We decided to focus the figure first before we run the
                % plot code so that there is no flickering
                if plotSettingRoot.FocusFigure.ActiveValue
                    internal.matlab.plotpicker.focusCurrentFigure;
                end
                
                ax = gca;
                autoPopulateCode = "";
                % Get supportedFeatures for the current axes
                supportedFeatures = internal.matlab.plotstab.PlotsTabUtils.getSupportedFeatures(ax);

                % Generate linkdata code
                if plotSettingRoot.LinkData.ActiveValue
                    linkCode = internal.matlab.plotstab.PlotsTabUtils.getLinkDataString(execString,...
                                plotName, selectionNames);
                    if ~isempty(linkCode)
                       autoPopulateCode = autoPopulateCode + newline + linkCode;
                    end
                end
                % Generate x-y-z labels only if GenerateLabels settings is
                % on. NOTE: For instances like WorkspaceBrowser,
                % labels/title/legend generation is always off.
                labelNames = [];
                if plotSettingRoot.GenerateLabels.ActiveValue
                    labelNames  = internal.matlab.plotstab.PlotsTabUtils.getLabelNamesFromSelection(selectionNames, varName);
                    labelsCode = internal.matlab.plotstab.PlotsTabUtils.getLabelsString(ax,...
                                plotName, labelNames, supportedFeatures);
                    if ~isempty(labelsCode)
                        autoPopulateCode = autoPopulateCode + newline + labelsCode;
                    end
                end
                % Generate title
                if plotSettingRoot.GenerateTitle.ActiveValue && supportedFeatures.Title
                    if isempty(labelNames)
                        labelNames  = internal.matlab.plotstab.PlotsTabUtils.getLabelNamesFromSelection(selectionNames, varName);
                    end
                    titleCode = internal.matlab.plotstab.PlotsTabUtils.getTitleString(ax,...
                                plotName, labelNames, varName);
                    autoPopulateCode = autoPopulateCode + newline + titleCode;
                end
                % Generate legend
                if plotSettingRoot.GenerateLegend.ActiveValue && supportedFeatures.Legend
                    legendCode = internal.matlab.plotstab.PlotsTabUtils.getLegendString(ax,...
                                plotName, selectionNames);
                    autoPopulateCode = autoPopulateCode + newline + legendCode;
                end
                % Just evaluate the plot generation code. 
                try
                    evalin('debug', autoPopulateCode);
                catch e
                    % We check for supported features before evaluating
                    % code, log any errors generated during evaluation.
                    internal.matlab.datatoolsservices.logDebug("plotstab::PlotsTabUtils::error", "AutoCodeGen:" + e.message);  
                end
                codeToBePublished = strcat(execString, autoPopulateCode);
                % This will just print the code to command window,
                % execution has already happend in the previous steps.
                internal.matlab.desktop.commandwindow.insertCommandIntoHistory(codeToBePublished);
            end
        end

        % This uses MetaDataService to return supported features for a
        % given plot. This is used to conditionally generate code for
        % labels/legends and titles.
        function featureSet = getSupportedFeatures(ax)
            metaDataService = matlab.plottools.service.MetadataService.getInstance();
            adapter = metaDataService.getMetaDataAccessor(ax);
            featureSet = adapter.getSupportedFeatures();
        end
    end
end



