classdef ModulesFactory
    %MODULESFACTORY is a factory class that provides factory methods for
    %creating the different appspace and toolstrip section View and
    %Controller classes.

    % Copyright 2020-2022 The MathWorks, Inc.

    %% Private Constructor
    methods(Access = private)
        function obj = ModulesFactory()
        end
    end

    %% Public static factory functions for all the modules.
    methods (Static)

        %% TOOLSTRIP
        function [view, controller] = getWriteSection(form)
            % Create and return the toolstrip write section View and
            % Controller classes.
            sectionName = "WriteSection";
            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getToolstripSection(form, sectionName);
        end

        function [view, controller] = getReadSection(form)
            % Create and return the toolstrip read section View and
            % Controller classes.
            sectionName = "ReadSection";
            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getToolstripSection(form, sectionName);

            mustBeA(view, "matlabshared.transportapp.internal.toolstrip.read.IView");
            if form.ShowFlushButton
                view.addFlushButtonToToolstrip();
            end
        end

        function [view, controller] = getAnalyzeSection(form)
            % Create and return the toolstrip analyze section View and
            % Controller classes.

            sectionName = "AnalyzeSection";
            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getToolstripSection(form, sectionName);
        end

        function [view, controller] = getCommunicationLogSection(form)
            % Create and return the toolstrip communication log section
            % View and Controller classes.
            sectionName = "CommunicationLogSection";
            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getToolstripSection(form, sectionName);
        end

        function [view, controller] = getExportSection(form)
            % Create and return the toolstrip export section View and
            % Controller classes.
            sectionName = "ExportSection";
            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getToolstripSection(form, sectionName);
        end

        %% APPSPACE
        function [view, controller] = getAppSpaceCommunicationLog(form)
            % Create and return the appspace communication log section View
            % and Controller classes.
            sectionName = "CommunicationLogSection";
            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getAppspaceSection(form, sectionName);
        end

        function manager = getPropertyInspectorManager(form)
            % Create and return the property inspector manager section.

            arguments
                form matlabshared.transportapp.internal.utilities.forms.AppSpaceForm
            end
            className = form.PropertyInspectorManager.ClassName;
            additionalInputArgs = form.PropertyInspectorManager.AdditionalParams;

           propertyInspectorLayout = form.PropertyInspectorLayout;
           propertyInspectorParentGrid = form.PropertyInspectorParentProps;

            grid = matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.createGridLayout ...
                (form.Parent,  propertyInspectorParentGrid);

            propInspector = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.createPropertyInspector ...
                (grid,  propertyInspectorLayout, struct.empty);

            inputArguments = "form, propInspector, additionalInputArgs";
            evalStr = className + "(" + inputArguments + ")";
            manager = eval(evalStr);
        end
    end

    %% Modules
    methods (Access = private, Static)
        function [view, controller] = getToolstripSection(form, sectionName)
            % Get a toolstrip section, based on the sectionName.
            arguments
               form  matlabshared.transportapp.internal.utilities.forms.ToolstripForm
               sectionName (1,1) string
            end

            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getViewAndController(form, sectionName);
        end

        function [view, controller] = getAppspaceSection(form, sectionName)
            % Get an appspace section, based on the sectionName.
            arguments
               form  matlabshared.transportapp.internal.utilities.forms.AppSpaceForm
               sectionName (1,1) string
            end

            [view, controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getViewAndController(form, sectionName);
        end

        function [view, controller] = getViewAndController(form, sectionName)
            % Get the view and controller for the section using the
            % Appspace or Toolstrip form.
            if isempty(form.Parent)
                throwAsCaller(MException(message("transportapp:utilities:EmptyParent")));
            end

            % Get the View
            view = getView(form, sectionName);

            % Get the Controller
            controller = getController(form, view, sectionName);

            % NESTED FUNCTION
            function view = getView(form, sectionName)
                % Create and return the View Class.

                % Extract the Entry class from the form.
                moduleName = sectionName + "View";

                % Prepare the View classname and input arguments that will be
                % invoked using eval.
                [className, additionalInputArgs] = ...
                    matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getEntryValuesFromForm(form, moduleName); %#ok<*ASGLU>
                parentPanel = form.Parent;

                % Evaluate the final string to get the View Class.
                viewEvalString = className + "(" + "parentPanel, additionalInputArgs)";
                view = eval(viewEvalString);
            end

            % NESTED FUNCTION
            function controller = getController(form, view, sectionName)
                % Create and return the Controller Class.

                % Extract the Entry class from the form.
                moduleName = sectionName + "Controller";

                % Prepare the Controller classname and input arguments that
                % will be invoked using eval.
                [className, additionalInputArgs] = ...
                    matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getEntryValuesFromForm(form, moduleName); %#ok<*ASGLU>

                % Prepare other input arguments for the Controller class
                % constructor, like the mediator and the viewConfiguration
                mediator = form.Mediator;
                viewConfiguration = matlabshared.transportapp.internal.utilities.viewconfiguration.ViewConfiguration(view); %#ok<*NASGU>

                % Evaluate the final string to get the Controller Class.
                controllerEvalString = className + "(" + "mediator, viewConfiguration, additionalInputArgs)";
                controller = eval(controllerEvalString);
            end
        end
    end

    %% Helper Functions
    methods (Static)
        function [className, additionalInputArgs] = getEntryValuesFromForm(form, moduleName)
            % Private Helper function to parse the form with the given
            % moduleName to extract the ClassName string and
            % additionalInputArgs data member of the Entry class.

            % entry is of type
            % matlabshared.transportapp.internal.utilities.forms.Entries
            entry = form.(moduleName);

            className = entry.ClassName;
            additionalInputArgs = entry.AdditionalParams;
        end
    end
end
