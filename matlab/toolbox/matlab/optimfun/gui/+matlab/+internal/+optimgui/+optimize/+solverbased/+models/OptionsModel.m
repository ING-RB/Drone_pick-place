classdef OptionsModel < matlab.internal.optimgui.optimize.models.AbstractTaskModel
    % The OptionsModel class manages a solver's options logic
    %
    % See also matlab.internal.optimgui.optimize.solverbased.models.SolverModel
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Access = protected)
        
        % Base MATLAB solver's require a different code syntax. The option names also
        % need to be converted to optimoptions names when viewed and stored in the State.
        % Use a logical to indicate an optimset solver
        isOptimSet (1, 1) logical
    end
    
    properties (Hidden, GetAccess = public, SetAccess = protected)
        
        % Create a table of all the solver's options. Table variables include
        % Category, DisplayLabel, Type, Widget, WidgetProperties, DefaultValue,
        % isViewed, and isDefault. Most of this meta-data is pulled from the solver's optimoptions object.
        % However, the table format lends itself much better to feeding into the option
        % view class components. Also, organizing the options like this
        % allows new options to view to be returned as a table and the view class
        % can use dot notation with the variables similar to the SolverInput objects
        ModelTable table
    end
    
    properties (GetAccess = public, SetAccess = protected)
        
        % The solver's optimoptions object. This contains most of the meta-data stored
        % in the ModelTable property. It is also used to validate new option values
        OptimOptions
        
        % Logical indicator that the associated solver has mutliple algorithms
        isMultiAlgorithm (1, 1) logical
    end
    
    properties (Dependent, Access = protected)
        
        % The solver's OptionsStore contains more meta-data. It is used for
        % multi-algorithm solvers
        OptionsStore
        
        % A subset of ModelTable, containing all options except Display and PlotFcn.
        % Display and PlotFcn options do not appear in the option dropdowns
        OptionsTable table
        
        % A subset of OptionsTable, containing options with an isViewed variable
        % value of false
        AvailableOptionsTable table
    end
    
    properties (Dependent, GetAccess = public, SetAccess = protected)
        
        % Return the unique categories of all available/unviewed options
        AvailableCategoryNames cell
        
        % Return the names of viewed options in the order they apppear in the view.
        % This is used by the updateView method of the Options view class so that
        % the option dropdowns are aligned with the model
        ViewedOptionNames cell
        
        % Return the option names needed for the generateCode() method
        OptionNamesForGeneratedCode cell
        
        % The algorithm dropdown items may be dependent on the constraints
        % set by the user. No need to worry about the dropdown items if it's
        % not visible.
        isAlgorithmViewed (1, 1) logical
    end
    
    properties (Dependent, SetObservable, AbortSet, GetAccess = public, SetAccess = protected)
        
        % Cellstr of algorithms valid given the constraints selected by the user
        ValidAlgorithms (1, :) cell
    end

    events

        % Notify listeners when the algorithm has changed
        AlgorithmChangedEvent
    end
    
    % Methods for dependent properties
    methods
        
        function value = get.OptionsTable(obj)
        ind = ~ismember(obj.ModelTable.Row, {'Display', 'PlotFcn'});
        value = obj.ModelTable(ind, :);
        end
        
        function value = get.OptionsStore(obj)
        value = getOptionsStore(obj.OptimOptions);
        end
        
        function value = get.AvailableOptionsTable(obj)
        value = obj.OptionsTable(~obj.OptionsTable.isViewed, :);
        end
        
        function value = get.AvailableCategoryNames(obj)
        value = unique(obj.AvailableOptionsTable.Category, 'stable')';
        end
        
        function value = get.ViewedOptionNames(obj)
        currentSolverViewedOptions = obj.OptionsTable.Row(obj.OptionsTable.isViewed, :);
        orderedOptionsSetByUser = fieldnames(obj.State.Options);
        value = intersect(orderedOptionsSetByUser, currentSolverViewedOptions, 'stable');
        end
        
        function value = get.OptionNamesForGeneratedCode(obj)
        % Call protected method so subclasses can override
        value = obj.getOptionNamesForGeneratedCode();
        end
        
        function value = get.isAlgorithmViewed(obj)
        value = obj.isMultiAlgorithm && obj.ModelTable{'Algorithm', 'isViewed'};
        end
        
        function set.ValidAlgorithms(obj, value)
        obj.ModelTable{'Algorithm', 'WidgetProperties'}{:}{2} = value;
        end
        
        function value = get.ValidAlgorithms(obj)
        value = obj.ModelTable{'Algorithm', 'WidgetProperties'}{:}{2};
        end
    end
    
    methods (Access = public)
        
        function obj = OptionsModel(state)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.models.AbstractTaskModel(...
            state);
        
        % Set the OptionsModel
        obj.setOptionsModel();
        end
        
        function value = getNextOptionTable(obj, categoryName)
        
        % Called by the Options view class when the user pushes the + image
        % to view another option. In this case categoryName is not an input argument
        % It's also called when the user changes a category dropdown. In that case, we need to view
        % an option for the specific new category they set.
        
        % If a category name is specified, return the next option for that category.
        % Else, return the next available option as sorted in OptionsTable
        if nargin > 1
            availableOptionsCategory = obj.AvailableOptionsTable(strcmp(obj.AvailableOptionsTable.Category, categoryName), :);
            optionName = availableOptionsCategory.Row{1};
        else
            optionName = obj.AvailableOptionsTable.Row{1};
        end
        value = obj.getOptionTable(optionName);
        end
        
        function value = getOptionTable(obj, optionName)
        
        % Return option table row
        value = obj.ModelTable(optionName, :);
        end
        
        function value = getOptionValue(obj, optionName)
        
        % Return option value from state
        value = obj.State.Options.(optionName);
        end
        
        function value = getPlotFcnValue(obj)
        
        % Return PlotFcn value from state
        value = obj.getOptionValue('PlotFcn');
        
        % PlotFcns can be multiselect, which requires extra handling. For example,
        % PlotFcn values for ga for not valid for fmincon. However, the state will
        % hold on to those values if the user sets them and changes solver
        
        % If PlotFcns have been set by the user, determine whether any of them
        % are valid for this solver
        if ~strcmp(value, '[]')
            
            % PlotFcns that have been set the user
            setNames = value;
            
            % All PlotFcns for this solver
            currentNames = obj.getPlotFcnNames();
            
            % PlotFcns for this solver that have been set by the user
            value = currentNames(ismember(currentNames, setNames));
            
            % If no PlotFcns for this solver are set, return empty brackets char
            if isempty(value)
                value = '[]';
            end
        end
        end
        
        function [textDisplayNames, textDisplayLabels] = getTextDisplayNames(obj)
        
        % Return Display option names and their labels as (1, :) cellstr.
        % Remove detailed 'none' and '-detailed' values
        textDisplayNames = setdiff(obj.OptimOptions.PropertyMetaInfo.Display.Values, ...
            {'none', 'iter-detailed', 'notify-detailed', 'final-detailed'}, 'stable');
        textDisplayLabels = matlab.internal.optimgui.optimize.utils.getMessage('Labels', erase(textDisplayNames, '-'));
        end
        
        function [plotFcnNames, plotFcnLabels] = getPlotFcnNames(obj)
        
        % Return PlotFcn option names and their labels as (1, :) cellstr
        % If this solver does not have the PlotFcn option, returns empty cells
        if ismember('PlotFcn', obj.ModelTable.Row)
            plotFcnNames = obj.OptimOptions.PropertyMetaInfo.PlotFcn.Values;
            plotFcnLabels = matlab.internal.optimgui.optimize.utils.getMessage('Labels', plotFcnNames);
        else
            plotFcnNames = cell(1, 0);
            plotFcnLabels = cell(1, 0);
        end
        end
        
        function [availableOptionNames, availableOptionLabels] = getRemainingOptionsForCategory(obj, categoryName)
        
        % Called by the options view class to update the items in the option
        % dropdowns as the user add/deletes options to view
        
        % Logical ind containing rows in AvailableOptionsTable of categoryName
        ind = strcmp(obj.AvailableOptionsTable.Category, categoryName);
        
        % Return the available option names and their labels as (1, :) cellstr
        availableOptionNames = obj.AvailableOptionsTable.Row(ind)';
        availableOptionLabels = obj.AvailableOptionsTable.DisplayLabel(ind)';
        end
        
        function addOption(obj, optionName)
        
        % Called by the Options view class when the user pushes the + image
        % to view another option. setOptionValue method is not needed because the value
        % of any added option is its default option and we know it's valid.
        
        % Update ModelTable isViewed column
        obj.ModelTable{optionName, 'isViewed'} = true;
        
        % Set option to its default value in the State and flag as the default value
        obj.setOptionsStateValue(optionName, obj.ModelTable{optionName, 'DefaultValue'}{:}, true);
        end
        
        function removeOption(obj, optionName)
        
        % Called by the Options view class when the user pushes the - image
        % to delete the option or deletes the option by changing to a new option
        % or option category in the dropdowns
        
        % Update ModelTable isViewed and isDefault variables
        obj.ModelTable{optionName, 'isViewed'} = false;
        obj.ModelTable{optionName, 'isDefault'} = true;
        
        % Reset OptimOptions value for the option
        obj.resetOptimoptionsValue(optionName);
        
        % Remove option as field from State Options structure
        obj.State.Options = rmfield(obj.State.Options, optionName);
        end
        
        function valid = setOptionValue(obj, optionName, value)
        
        % Called by the Options view class when the user changes an option value and
        % by this class when importing options set in the State. Returns a logical of whether the
        % option was set sucessfully
        
        % Determine if setting to the default value
        isDefault = isequal(value, obj.ModelTable{optionName, 'DefaultValue'}{:});
        
        % Is the option value the default value for the current solver OR coming from a
        % WorkspaceDropDown that already validates the input?
        if isDefault || strcmp(obj.ModelTable{optionName, 'Widget'}{:}, 'matlab.ui.control.internal.model.WorkspaceDropDown')
            
            % Value is valid, even though it may fail the optimoptions assignment
            % in validateOption method (numberOfVariables, etc.)
            valid = true;
        else
            
            % Convert value from View to value accepted by optimoptions
            optimoptionsValue = obj.convert2OptimOptionsValue(optionName, value);
            
            % Validate optimoptionsValue
            valid = obj.validateOption(optionName, optimoptionsValue);
        end
        
        % If the option value is valid, update the State
        if valid
            obj.setOptionsStateValue(optionName, value, isDefault);
        end
        end

        function algorithmChanged(obj)

            % Re-set model and notify listeners
            obj.setOptionsModel();
            obj.notify('AlgorithmChangedEvent');
        end
        
        function setPlotFcnValue(obj, value)
        
        % Called by the Diagnostics view class when the user changes makes any changes to
        % the PlotFcn checkbox array. The view sends in the names of all checked
        % PlotFcn values, or is empty if none are checked
        
        % Append current value from this solver with values in State that are NOT related to this solver.
        % This is required because the view passes in all checked names, so successive checks will send
        % in some of the same values already in the State
        statePlotFcnValues = reshape(obj.State.Options.PlotFcn, 1, []);
        value = [value, setdiff(statePlotFcnValues, ['[]', obj.getPlotFcnNames()])];
        if isempty(value)
            value = '[]';
        end
        
        % Determine if setting to the default value
        isDefault = isequal(value, obj.ModelTable{'PlotFcn', 'DefaultValue'}{:});
        
        % Set option value in State
        obj.setOptionsStateValue('PlotFcn', value, isDefault);
        end
        
        function sortOptionsStateStructFields(obj, orderedOptions)
        
        % Order the fields of the State's Options structure by their order in the view
        % Start with the current solver's ordered options from the view
        % Next, append options in State that do NOT exist for the current solver/algorithm
        % Then, append Display and PlotFcn last
        notThisSolverOptions = setdiff(fieldnames(obj.State.Options)', ...
            [orderedOptions, {'Display', 'PlotFcn'}]);
        obj.State.Options = orderfields(obj.State.Options, [orderedOptions, notThisSolverOptions, ...
            {'Display', 'PlotFcn'}]);
        end
        
        function setOptionsModel(obj)
        
        % Called on construction of an OptionsModel object. It is also called by
        % the view class whenever Algorithm is changed.
        
        % Set OptimOptions and isOptimSet properties
        try
            obj.OptimOptions = optimoptions(obj.State.SolverName);
            obj.isOptimSet = false;
        catch
            obj.OptimOptions = optim.options.(matlab.internal.optimgui.optimize.utils.upperFirstLetter(obj.State.SolverName));
            obj.isOptimSet = true;
        end
        
        % Set isMultiAlgorithm property
        obj.isMultiAlgorithm = isa(obj.OptimOptions, 'optim.options.MultiAlgorithm');

        % Extra handling for multi-algorithm solvers
        cnlsDefaultAlgChange = false;
        if obj.isMultiAlgorithm

            % Suppress warnings when setting the algorithm optimoptions value
            warnstate(1) = warning("off", "optim:options:Intlinprog:AlgorithmDeprecation");
            warnstate(2) = warning("off", "optim:options:Linprog:AlgorithmValueDeprecation");
            cleanupObj = onCleanup(@()warning(warnstate));
        
        % get valid algorithms
            validAlgorithms = obj.getValidAlgorithms;

            % get default algorithm
            defaultAlgorithm = obj.OptimOptions.Algorithm;

            % for cnls, the default algorithm is different
            cnlsDefaultAlgChange = any(strcmp(obj.OptimOptions.SolverName, {'lsqnonlin', 'lsqcurvefit'})) && ...
                ~any(strcmp(defaultAlgorithm, validAlgorithms));
            if cnlsDefaultAlgChange
                defaultAlgorithm = 'interior-point';
                obj.OptimOptions.Algorithm = defaultAlgorithm;
            end

            % Check if algorithm option is visible to user
            if isfield(obj.State.Options, 'Algorithm')
                % If algorithm visible to user is NOT valid for the current solver (either ever or
                % because of the current constraint types selected), set the Algorithm value in the State
                % to this solver's default.
                % Else, update the OptimOptions object with the value from the State
                if ~any(strcmp(validAlgorithms, obj.State.Options.Algorithm))
                    obj.State.Options.Algorithm = defaultAlgorithm;
                else
                    obj.OptimOptions.Algorithm = obj.State.Options.Algorithm;
                end
            end
        end

        % Make ModelTable for the current solver. It is important for the OptimOptions
        % algorithm to be set correctly before calling makeTable because different
        % algorithms result in different available options
        obj.makeTable();

        % Check for possible auto default algorithm change for constrained nonlinear least-squares
        if cnlsDefaultAlgChange
            obj.ModelTable{'Algorithm', 'DefaultValue'} = {defaultAlgorithm};
            obj.ModelTable{'Algorithm', 'isDefault'} = ~isfield(obj.State.Options, 'Algorithm') || ...
                strcmp(obj.State.Options.Algorithm, defaultAlgorithm);
        end
        
        % Cell array of options set by the user
        optionsSet = fieldnames(obj.State.Options);
        
        % Can only view options that are relevant to the current solver/algorithm
        ind = ismember(obj.ModelTable.Row, optionsSet);
        options2View = obj.ModelTable.Row(ind, :);
        
        % Import options from state
        obj.importOptions(options2View);
        end
        
        function tf = isSet(~)

        % We always consider the Options model to be set
        tf = true;
        end
        
        function [code, clearCode] = generateCode(obj)
        
        % Called by the SolverModel class when generating code
        
        % Place options into a 2-by-n cell array, row 1 for option name, row 2 for option value
        % Only generate code for nondefault option values
        codeOptions = obj.OptionNamesForGeneratedCode;
        C = cell(2, numel(codeOptions));
        for count = 1:numel(codeOptions)
            optionName = codeOptions{count};
            
            % Need to convert OptimSet names to "old" names when generating code
            codeOptionName = obj.getCodeOptionName(optionName);
            
            % Need to add quotes around option name
            C{1, count} = ['"', codeOptionName, '"'];
            
            % Logic to handle different option value types/situations
            
            % Is the option value in the State a char?
            if(ischar(obj.State.Options.(optionName)))
                
                % Enum types need quotes around option value.
                % So do fcn types when there built-in values that we display in a dropdown...
                % Except, when the dropdown contains empty and a selection
                % Else, code is same as State value
                if strcmp(obj.ModelTable{optionName, 'Type'}, 'enum') || ...
                        (strcmp(obj.ModelTable{optionName, 'Type'}, 'fcn') && ...
                        strcmp(obj.ModelTable{optionName, 'Widget'}, 'matlab.ui.control.DropDown') && ...
                        ~strcmp(obj.State.Options.(optionName), '[]'))
                    C{2, count} = ['"', obj.State.Options.(optionName), '"'];
                else
                    C{2, count} = obj.State.Options.(optionName);
                end
                
                % If value in the State is numeric, need to convert state value to char
            elseif(isnumeric(obj.State.Options.(optionName)))
                C{2, count} = num2str(obj.State.Options.(optionName));
                
                % If value in the State is logical, need to convert code to 'true'/'false'
            elseif(islogical(obj.State.Options.(optionName)))
                % "Cast" logical to string then to char
                C{2, count} = char(string(obj.State.Options.(optionName)));
            end

            % If the option value was input from a workspace dropdown,
            % wrap the value with back-ticks
            if strcmp(obj.ModelTable{optionName, 'Widget'}, 'matlab.ui.control.internal.model.WorkspaceDropDown')
                C{2, count} = matlab.internal.optimgui.optimize.utils.addBackTicks(C{2, count});
            end
        end
        
        % Flatten options cell array
        C = C(:)';
        
        % Add PlotFcn option if necessary
        if ismember('PlotFcn', obj.ModelTable.Row) && ~isequal(obj.getPlotFcnValue(), obj.ModelTable{'PlotFcn', 'DefaultValue'}{:})
            % Return the current PlotFcn value
            plotCode = obj.getPlotFcnValue();
            
            % If the plotCode is not '[]', add '' to each PlotFcn value
            if ~strcmp(plotCode, '[]')
                for count = 1:numel(plotCode)
                    plotCode{count} = ['"', plotCode{count}, '"'];
                end
                
                % If more than 1 PlotFcn value is set, need to pass as a cell array.
                % Apppend curly brackets at beginning and end
                if numel(plotCode) > 1
                    plotCode{1} = ['[', plotCode{1}];
                    plotCode{end} = [plotCode{end}, ']'];
                end
            end
            
            % Need to convert OptimSet name to "old" name when generating code
            if obj.isOptimSet
                codeOptionName = 'PlotFcns';
            else
                codeOptionName = 'PlotFcn';
            end
            C = [C, ['"', codeOptionName, '"'], plotCode];
        end
        
        % If there are nondefault options, generate code
        % Else, return empty code
        if ~isempty(C)
            % Add the call to optimoptions/optimset
            if obj.isOptimSet
                optionsCall = 'options = optimset(';
            else
                optionsCall = ['options = optimoptions("', obj.OptimOptions.SolverName, '",'];
            end
            % Append options call and join all cell aray elements with a comma
            C2 = [optionsCall, strjoin(C, ',')];
            % Add newlines as necessary if the code char is long
            code = matlab.internal.optimgui.optimize.utils.reformatCode(C2);
            % Code comment for call to optimoptions/optimset and ');' to close call to optimoptions/optimset
            code = [[matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'OptionsComment'), newline], code, ');', newline, newline];
            % Code to clear the options variable
            clearCode = 'options ';
        else
            code = '';
            clearCode = '';
        end
        end
        
        function tf = validateOption(obj, optionName, value)
        
        % Called by setOptionValue method

        % Suppress warnings when setting any optimoptions value, including algorithm
        warnstate(1) = warning("off", "optim:options:Intlinprog:OptionDeprecation");
        warnstate(2) = warning("off", "optim:options:Intlinprog:AlgorithmDeprecation");
        warnstate(3) = warning("off", "optim:options:Linprog:AlgorithmValueDeprecation");
        cleanupObj = onCleanup(@()warning(warnstate));
        
        % Validate option
        % [~, tf] = obj.OptimOptions.PropertyMetaInfo.(optionName).validate(optionName,value);
        try
            obj.OptimOptions.(optionName) = value;
            tf = true;
        catch
            tf = false;
        end
        end

        function haveChanged = updateValidAlgorithms(obj)
        
        % Called by the updateAlgorithmSelections() method in the Options view class.
        % Default to returning false, which indicates there was no change
        % to valid algorithms
        haveChanged = false;

        % Quick return if the solver does NOT have multiple algorithms
        if ~obj.isMultiAlgorithm
            return
        end

        % Return the currently valid algorithms
        currentAlgorithms = obj.getValidAlgorithms();

        % If the valid algorithms have changed, update them
        haveChanged = ~isequal(obj.ValidAlgorithms, currentAlgorithms);
        if haveChanged
            obj.ValidAlgorithms = currentAlgorithms;
        end
        end
    end
    
    methods (Access = protected)
        
        function makeTable(obj)

        % Determine option names. Need to limit to current algorithm
        % options for multialgorithm solvers
        if obj.isMultiAlgorithm
            Name = obj.OptionsStore.DisplayOptions{obj.OptionsStore.AlgorithmIndex}';
        else
            Name = fieldnames(obj.OptimOptions);
        end
        
        % For each option name, get additional meta-data
        Category = cell(size(Name));
        DisplayLabel = cell(size(Name));
        Type = cell(size(Name));
        DefaultValue = cell(size(Name));
        Tooltip = cell(size(Name));
        Widget = cell(size(Name));
        WidgetProperties = cell(size(Name));
        
        % Retrieve MetaInfo outside of the loop for efficiency
        MetaInfo = obj.OptimOptions.PropertyMetaInfo;
        
        for count = 1:numel(Name)
            
            % Grab references to the option & its meta-info for code clarity below
            thisOption = Name{count};
            thisOptMetaInfo = MetaInfo.(thisOption);
            
            % Borrow fminunc HessianFcn meta-info for fmincon when Algorithm
            % is trust-region-reflective
            if strcmp(thisOption, 'HessianFcn') && ...
                    strcmp(obj.OptimOptions.SolverName, 'fmincon') && ...
                    strcmp(obj.OptimOptions.Algorithm, 'trust-region-reflective')
                thisOpts = optim.options.Fminunc;
                thisOptMetaInfo = thisOpts.PropertyMetaInfo.HessianFcn;
            end
            
            % Get Category, DisplayLabel, Type, and DefaultValue from OptimOptions
            Category{count} = thisOptMetaInfo.Category;
            DisplayLabel{count} = thisOptMetaInfo.DisplayLabel;
            Type{count} = thisOptMetaInfo.TypeKey;
            Widget{count} = thisOptMetaInfo.Widget;
            WidgetProperties{count} = thisOptMetaInfo.WidgetData;
            DefaultValue{count} = obj.OptimOptions.(thisOption);
            
            % Get Tooltip for the OptionDropDown
            Tooltip{count} = getString(message('MATLAB:optimfun_gui:Tooltips:options', ...
                obj.getCodeOptionName(Name{count})));
            
            % Extra handling for DefaultValue
            if strcmp(thisOption, 'Algorithm')
                DefaultValue{count} = obj.OptionsStore.DefaultAlgorithm;
            elseif isempty(DefaultValue{count})
                DefaultValue{count} = '[]';
            elseif strcmp(Type{count}, 'fcn')
                % Value for a dropdown needs to be char, not cell
                if iscell(DefaultValue{count})
                    DefaultValue{count} = DefaultValue{count}{1};
                end
                % More handling if default value is a fcn handle
                if isa(DefaultValue{count}, 'function_handle')
                    if strcmp(thisOption, 'PlotFcn')
                        % surrogateopt has a non-empty default PlotFcn
                        DefaultValue{count} = {func2str(DefaultValue{count})};
                    else
                        % Can't put a function handle in editbox or as the value of a dropdown,
                        % need to convert to char
                        DefaultValue{count} = func2str(DefaultValue{count});
                    end
                end
            end
            
            % Extra handling for some option types. 
            % string(double matrix) returns a non-scalar which will
            % not work when passed as argument (holes) to message. numeric
            % types must use mat2str not string().
            if any(strcmp(Type{count}, {'numeric', 'integer'}))
                % Special tooltips for some options
                if any(strcmp(thisOption, {'FiniteDifferenceStepSize', 'PopulationSize'}))
                    widgetTooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', thisOption);
                elseif strcmp(thisOption, 'InertiaRange') || ...
                       strcmp(thisOption, 'InitialPopulationRange') 
                    widgetTooltip = getString(message('MATLAB:optimfun_gui:Tooltips:OptionDefaultValue', ...
                        mat2str(DefaultValue{count})));
                else                    
                    widgetTooltip = getString(message('MATLAB:optimfun_gui:Tooltips:OptionDefaultValue', ...
                        char(string(DefaultValue{count}))));
                end
                
                % Can't use numeric edit field if default value is text
                if strcmp(Widget{count}, 'matlab.ui.control.NumericEditField') && ...
                        ~isnumeric(DefaultValue{count})
                    Widget{count} = 'matlab.ui.control.EditField';
                    WidgetProperties{count} = cell(0);
                    DefaultValue{count} = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'DefaultOptionValue');
                end
            else
                % Tooltip for the option widget
                widgetTooltip = getString(message('MATLAB:optimfun_gui:Tooltips:OptionDefaultValue', ...
                    char(string(DefaultValue{count}))));
            end
            
            % If widget is WorkspaceDropDown, set DefaultValue and append widgetTooltip
            if strcmp(Widget{count}, 'matlab.ui.control.internal.model.WorkspaceDropDown')
                DefaultValue{count} = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultDropDownValue;
                widgetTooltip = [matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'WorkspaceVariable'), ...
                    ', ', obj.getOptionSpecs(Name{count}), blanks(1), widgetTooltip]; %#ok
            end
            
            % Add Tooltip to WidgetProperties
            WidgetProperties{count} = [WidgetProperties{count}, {'Tooltip', widgetTooltip}];
        end
        
        % No options are viewed initially, importOptions method will update from State
        isViewed = false(size(Name));
        
        % All options are their default value initially, importOptions method will update from State
        isDefault = true(size(Name));
        
        % Construct ModelTable
        obj.ModelTable = table(Category, DisplayLabel, Tooltip, Type, Widget, ...
            WidgetProperties, DefaultValue, isViewed, isDefault, 'RowNames', Name);
        
        % Sort table alphabetically by Category, then option name (stored as the rows)
        % Note, Category is a translated value. Order will vary by locale
        obj.ModelTable = sortrows(obj.ModelTable, {'Category', 'Row'});
        
        % If MultiAlgorithm, update valid Algorithms
        if obj.isMultiAlgorithm
            obj.ValidAlgorithms = obj.getValidAlgorithms();
        end
        end
        
        function optimoptionsValue = convert2OptimOptionsValue(obj, optionName, value)
        
        % Sometimes, using optimoptions assignment requires converting the view's
        % widget value to something optimoptions will accept.
        % Catch special case and convert value from editable textboxes to double.
        % Else, return the value from the view
        if ismember(obj.ModelTable{optionName, 'Type'}, {'numeric', 'integer'}) && ~isa(value, 'double')
            optimoptionsValue = str2double(value);
        else
            optimoptionsValue = value;
        end
        end

        function resetOptimoptionsValue(obj, optionName)
        
        % Called by removeOption().

        % Resetting the optimoptions value is separated in its own protected
        % method so that subclasses can override its behavior
        
        % Reset optimoptions value for the option
        obj.OptimOptions = resetoptions(obj.OptimOptions, optionName);
        end
        
        function setOptionsStateValue(obj, optionName, value, isDefault)
        
        % Update option value in State
        obj.State.Options.(optionName) = value;
        
        % Update isDefault variable in ModelTable
        obj.ModelTable{optionName, 'isDefault'} = isDefault;
        end
        
        function importOptions(obj, optionNames)
        
        % Loop through options to import from the State
        for count = 1:numel(optionNames)
            
            % Current option name
            optionName = optionNames{count};
            
            % Update ModelTable isViewed column
            obj.ModelTable{optionName, 'isViewed'} = true;
            
            % Get value in State for this option
            value = obj.State.Options.(optionName);
            
            % Sometimes, a different widget is used for the same option between solvers/algorithm.
            % Check for switiching between uieditfield/uinumericeditfield and convert the value
            if strcmp(obj.ModelTable{optionName, 'Widget'}, 'matlab.ui.control.EditField') && ~isa(value, 'char')
                value = num2str(value);
            elseif strcmp(obj.ModelTable{optionName, 'Widget'}, 'matlab.ui.control.NumericEditField') && ...
                    ~isa(value, 'double')
                value = str2double(value);
            end
            
            % optimoptions allows fcns to be set to any text. However, sometimes users have set a
            % built-in value for some fcn option, but that built-in value does not exist for another solver
            % with the same fcn option name. When we are using a dropdown widget for the option, this is a problem
            % because we can't set a dropdown to a value that is not one of its items. Set value to NaN
            % so optimoptions assignment will be invalid.
            if strcmp(obj.ModelTable{optionName, 'Type'}, 'fcn') && ...
                    strcmp(obj.ModelTable{optionName, 'Widget'}, 'matlab.ui.control.DropDown') && ...
                    ~strcmp(optionName, 'PlotFcn') && ...
                    ~ismember(value, obj.ModelTable{optionName, 'WidgetProperties'}{:}{...
                    find(strcmp(obj.ModelTable{optionName, 'WidgetProperties'}{:}, 'Items')) + 1})
                value = NaN;
            end
            
            % If the option value from the State cannot be set for this solver,
            % update the State with this solver's default value for the option
            % and pass in flag for default value
            if ~obj.setOptionValue(optionName, value)
                obj.setOptionsStateValue(optionName, obj.ModelTable{optionName, 'DefaultValue'}{:}, true);
            end
        end
        end

        function optionNames = getOptionNamesForGeneratedCode(obj)

        % Return the non-default viewed option names. Append 'Display'
        % at the end so its code is generated last since it is in the relative
        % bottom position of the view.
        
        % Note obj.ViewedOptionNames is a dependent property that removes
        % both 'Display' and 'PlotFcn'. 'PlotFcn' is handled separately in
        % the generateCode() method so we only need to add back 'Display'
        viewedNames = [obj.ViewedOptionNames; 'Display'];
        isDefault = obj.ModelTable{viewedNames, 'isDefault'};
        optionNames = viewedNames(~isDefault);
        end
        
        function codeOptionName = getCodeOptionName(obj, optionName)
        
        % Need to convert OptimSet names to "old" names when generating code
        codeOptionName = optionName;
        if obj.isOptimSet
            % Convert to "optimset" option name
            if ~strcmp(optionName,'FunctionTolerance')
                codeOptionName = optim.options.OptionAliasStore.getAlias(optionName,'',[]);
            else
                % The OptionAliasStore is wired for optimoptions use
                % and doens't have the optimset name for
                % FunctionTolerance
                codeOptionName = 'TolFun';
            end
        end
        end
        
        function validAlgorithms = getValidAlgorithms(obj)
        
        % The get.ValidAlgorithms pulls from obj.ModelTable. This is done to
        % prevent us from re-calculating the logic below everytime that property
        % is queried. However, when changing solvers, a decision needs to be made on
        % whether the current algorithm is valid before the table is created.
        % Use this function to return the valid algorithms
        
        % All algorithms for the current solver
        allAlgorithms = obj.OptimOptions.PropertyMetaInfo.Algorithm.Values;
        
        % Viewed constraints are synced with state's ConstraintType
        % Remove 'None' and 'Unsure'
        selectedConstraints = setdiff(reshape(obj.State.ConstraintType, 1, []), ...
            {'None', 'Unsure'}, 'stable');
        
        % For fmincon and quadprog, remove trust-region-reflective if LinearEquality
        % is not the only constraint OR Bounds are not the only constraints.
        % For lsqlin, remove trust-region-reflective if Bounds are not the only constraints.
        % Else, set all algorithm as valid
        if any(strcmp(obj.OptimOptions.SolverName, {'fmincon', 'quadprog'})) && ...
                (~(isempty(setdiff(selectedConstraints, 'LinearEquality')) || ...
                isempty(setdiff(selectedConstraints, {'LowerBounds', 'UpperBounds'}))))
            validAlgorithms = setdiff(allAlgorithms, 'trust-region-reflective', 'stable');
        elseif strcmp(obj.OptimOptions.SolverName, 'lsqlin') && ...
                ~isempty(setdiff(selectedConstraints, {'LowerBounds', 'UpperBounds'}))
            validAlgorithms = setdiff(allAlgorithms, 'trust-region-reflective', 'stable');
        elseif any(strcmp(obj.OptimOptions.SolverName, {'lsqnonlin', 'lsqcurvefit'})) && ...
                any(ismember(selectedConstraints, {'LinearInequality', 'LinearEquality', ...
                'NonlinearConstraintFcn', 'SecondOrderCone'}))
            validAlgorithms = setdiff(allAlgorithms, ...
                {'trust-region-reflective', 'levenberg-marquardt'}, 'stable');
        else
            validAlgorithms = allAlgorithms;
        end
        end

        function msg = getOptionSpecs(obj, optionName)
        
        % Parse the error message thrown by optimoptions to make it smaller,
        % use colon to parse, for example:
        % 'Invalid value for OPTIONS parameter {0}: must be a positive integer.' is returned as
        % 'must be a positive integer.'
        
        % Called for only numeric or matstruct type options. Note, some ga/gamultiobj options
        % like InitialPopulationMatrix allow setting to NaN. Therefore a char input ('invalidInput')
        % is used here to prompt the error message
        
        [~, ~, ~, errMsg] = obj.OptimOptions.PropertyMetaInfo.(optionName).validate(optionName, 'invalidInput');
        idx = strfind(errMsg, ':');
        msg = strip(errMsg(idx + 1:end));
        end
    end
end
