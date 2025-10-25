classdef ConfirmInteractor < matlab.uiautomation.internal.interactors.ModalDialogsInteractor &...
        ... Access to "isViewReady"
        matlab.ui.internal.componentframework.services.optional.ViewReadyInterface
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2023 - 2024 The MathWorks, Inc.
    
    properties
        Fig
        Dispatcher
        DialogType = 'uiconfirm'
    end
    
    methods
        function obj = ConfirmInteractor(actor)
            obj.Fig = actor.Component;
            obj.Dispatcher = actor.Dispatcher;
        end
        
        function chooseDialog(obj, varargin)

            narginchk(2, 3);

            if (nargin == 2)
                % [] is used to keep argument position same as user inputs - g3253429
                obj.chooseNonBlockingDialog([], [], varargin{:});
            end

            if (nargin == 3)
                % for case: creation of confirmation dialog blocks access
                % to MATLAB Command Window
                % [] is used to keep argument position same as user inputs - g3253429
                obj.chooseBlockingDialog([], [], varargin{:});
            end

        end

        function dismissDialog(obj, varargin)
            
            narginchk(1, 2);

            if (nargin == 1)
                obj.dismiss();
            end

            if (nargin == 2)
                % [] is used to keep argument position same as user inputs - g3253429
                obj.dismissBlockingDialog([], [], varargin{:});
            end

        end
    end

    methods(Access=private)
        

        function chooseNonBlockingDialog(obj, ~, ~, choice)
            
            arguments
                obj (1,1)
                ~
                ~
                choice {validateChoice}
            end

            obj.chooseOption(choice);

        end

        function chooseBlockingDialog(obj, ~, ~, dialogTriggerFcn, choice)
            
            arguments
                obj (1,1)
                ~
                ~
                dialogTriggerFcn (1,1) function_handle
                choice {validateChoice}
            end
            
            % Poll for the figure's view readiness before registering the unblock function
            % because matlab.ui.internal.dialog.DialogController uses
            % if ~figController.IsFigureViewReady
            %   waitfor(figController, 'IsFigureViewReady', true)
            % end
            % before sending message to the client to create the confirmation dialog
            % 
            % ATF needs to ensure that the waitfor statement is not called. Otherwise, the
            % registered unblock function, which is supposed to unblock the confirmation dialog
            % would be called, resulting in unexpected failure
            pollForFigureViewReady(obj.Fig);

            cleaner = obj.registerFunctionHandleToStack(@()obj.chooseOption(choice));

            % Execute Trigger Function
            dialogTriggerFcn();

            delete(cleaner);

        end

        function dismissBlockingDialog(obj, ~, ~, dialogTriggerFcn)
        
            arguments
                obj (1,1)
                ~
                ~
                dialogTriggerFcn (1,1) function_handle
            end
            
            % Poll for the figure's view readiness before registering the unblock function
            % because matlab.ui.internal.dialog.DialogController uses
            % if ~figController.IsFigureViewReady
            %   waitfor(figController, 'IsFigureViewReady', true)
            % end
            % before sending message to the client to create the confirmation dialog
            % 
            % ATF needs to ensure that the waitfor statement is not called. Otherwise, the
            % registered unblock function, which is supposed to unblock the confirmation dialog
            % would be called, resulting in unexpected failure
            pollForFigureViewReady(obj.Fig);
            
            cleaner = obj.registerFunctionHandleToStack(@()obj.dismiss());

            % Execute Trigger Function
            dialogTriggerFcn();

            delete(cleaner);
        
        end

        function chooseOption(obj, choice)
            obj.Dispatcher.dispatch(obj.Fig, 'chooseDialog', 'dialogType', obj.DialogType, 'choice', choice);
        end

        function dismiss(obj)
            obj.Dispatcher.dispatch(obj.Fig, 'dismissDialog', 'dialogType', obj.DialogType);
        end
    end
end

function validateChoice(choice)
    if(ischar(choice) || isstring(choice))
        mustBeTextScalar(choice);
    else
        validateattributes(choice, {'numeric'}, {'scalar', 'positive', 'integer'});
    end
end

function pollForFigureViewReady(fig)
    t0 = tic;
    while ~fig.isViewReady && toc(t0) <= 60
        drawnow limitrate;
    end
end