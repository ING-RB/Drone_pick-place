classdef (Abstract) BaseDialog < ...
        matlabshared.transportapp.internal.visamodaldialog.IModalDialogFunctionality & ...
        matlabshared.transportapp.internal.utilities.ITestable
    %BASEDIALOG is the base class for any Modal Dialog Window for the visa
    %explorer app. It contains operations for construction and teardown of
    %the modal dialog window.

    % Copyright 2022-2023 The MathWorks, Inc.

    methods (Abstract)
        % Returns a populated DialogBuilderForm instance for construction
        % of the modal dialog window, depending on the type of interface -
        % VXI-11, HiSLIP, or Socket.
        form = getDialogBuilderForm(obj);

        % Returns the resource string constructed using the modal dialog
        % window, depending on the type of interface -
        % VXI-11, HiSLIP, or Socket.
        resourceString = getResourceString(obj);
    end

    properties
        Controller = ...
            matlabshared.transportapp.internal.visamodaldialog.DialogBuilderController.empty
    end

    properties(Dependent, SetAccess = ?matlabshared.transportapp.internal.utilities.ITestable)
        % Dictates whether the modal dialog window can be closed or not.
        Closeable
    end

    properties (Access = ?matlabshared.transportapp.internal.utilities.ITestable)
        AllowListenerSetup (1, 1) logical = true
    end

    %% Lifetime
    methods
        function obj = BaseDialog(varargin)
            arguments (Repeating)
                varargin matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
            end

            narginchk(0, 1);
            if nargin == 0
                builder = matlabshared.transportapp.internal.visamodaldialog.DialogBuilder(obj.BuilderConstants);
                viewConfiguration = matlabshared.transportapp.internal.utilities.viewconfiguration.ViewConfiguration(builder);
            else
                viewConfiguration = varargin{1};
            end

            obj.Controller = ...
                matlabshared.transportapp.internal.visamodaldialog.DialogBuilderController(viewConfiguration);
        end
    end

    %% API's exposed by the Dialog class
    methods
        function form = construct(obj)
            form = obj.getDialogBuilderForm();
            form.GenerateResourceFcnHandle = @obj.generateResourceStringFcn;
            obj.Controller.construct(form);

            if obj.AllowListenerSetup
                obj.Controller.setupListeners(form);
            end
        end

        function teardown(obj)
            obj.Controller.close();
        end

        function resourceString = generateResourceStringFcn(obj, ~, evt)
            import transportapp.visadev.internal.VisadevIdentification
            form = evt.Data;
            resourceString = obj.getResourceString(form);
            obj.Controller.populateResourceString(resourceString);
        end
    end

    %% Getters and Setters
    methods
        function val = get.Closeable(obj)
            val = obj.Controller.Closeable;
        end
    end
end
