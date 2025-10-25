classdef FigureInteractor < matlab.uiautomation.internal.interactors.AbstractContainerComponentInteractor & ...
        matlab.uiautomation.internal.interactors.SelctionTypeInteractorHelper
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2024 The MathWorks, Inc.
    
    methods
        
        function uipress(actor, varargin)
            import matlab.uiautomation.internal.Modifiers;
            import matlab.uiautomation.internal.Buttons;
            
            fig = actor.Component;
            parser = actor.parseInputs(varargin{:});
            
            posArgs = {};
            if ~ismember("Position", parser.UsingDefaults)
                position = actor.convertToPixelUnits(parser.Results.Position);
                posArgs = getPositionArgs(position);
            end

            selectionType = actor.validateSelectionType(parser.Results.SelectionType);
            
            switch selectionType
                case "extend"
                    modifier = Modifiers.SHIFT;
                    actor.Dispatcher.dispatch(fig, 'uipress', posArgs{:}, 'Modifier', modifier);
                case "alt"
                    button = Buttons.RIGHT;
                    actor.Dispatcher.dispatch(fig, 'uipress', posArgs{:}, 'Button', button);
                case "open"
                    actor.Dispatcher.dispatch(fig, 'uidoublepress', posArgs{:});
                otherwise % "normal"
                    % Get all explicitly specified arguments except for
                    % Position which has already been stored in posArgs
                    explicitlySpecified = rmfield(parser.Results, parser.UsingDefaults);
                    if isfield(explicitlySpecified, 'Position')
                        explicitlySpecified = rmfield(explicitlySpecified, 'Position');
                    end
                    if isfield(explicitlySpecified, 'Button')
                        explicitlySpecified.Button = actor.getButton(explicitlySpecified.Button);
                    end
                    if isfield(explicitlySpecified, 'Modifier') 
                        explicitlySpecified.Modifier = actor.getModifier(explicitlySpecified.Modifier);
                    end
                    nameValueArgs = namedargs2cell(explicitlySpecified);
                    actor.Dispatcher.dispatch(fig, 'uipress', posArgs{:}, nameValueArgs{:});
            end
        end
        
        function uihover(actor, varargin)
            
            narginchk(1,2);
            
            parser = actor.parseInputs(varargin{:});
            
            posArgs = {};
            if ~ismember("Position", parser.UsingDefaults)
                position = actor.convertToPixelUnits(parser.Results.Position);
                posArgs = getPositionArgs(position);
            end
            
            fig = actor.Component;
            actor.Dispatcher.dispatch(fig, 'uihover', posArgs{:});
        end
        
        function uidrag(actor, from, to, varargin)
            import matlab.uiautomation.internal.Modifiers;
            import matlab.uiautomation.internal.Buttons;
            
            narginchk(3, Inf);

            actor.validatePosition(from);
            actor.validatePosition(to);

            from = actor.convertToPixelUnits(from);
            to = actor.convertToPixelUnits(to);

            xyRowwise = [from; to].';
            
            parser = inputParser;
            parser.addParameter("SelectionType", "normal");
            parser.parse(varargin{:});
            
            % explicitly no "open" here
            selectionType = validatestring(parser.Results.SelectionType, ...
                ["normal" "extend" "alt"]);
            
            fig = actor.Component;
            
            args = {fig, 'uidrag', 'X', xyRowwise(1,:), 'Y', xyRowwise(2,:)};
            switch selectionType
                case "extend"
                    args = [args {'Modifier', Modifiers.SHIFT}];
                case "alt"
                    args = [args {'Button', Buttons.RIGHT}];
            end
            actor.Dispatcher.dispatch(args{:});
        end
        
        function uicontextmenu(actor, menu, position)
            arguments
                actor
                menu (1,1) matlab.ui.container.Menu {validateParent(actor, menu)}
                position (1, 2) double = missing
            end
            
            posArgs = {};
            if ~ismissing(position)
                actor.validatePosition(position);
                position = actor.convertToPixelUnits(position);
                posArgs = getPositionArgs(position);
            end
            
            fig = actor.Component;
            actor.Dispatcher.dispatch(fig, 'uicontextmenu', posArgs{:});

            menuInteractor = matlab.uiautomation.internal.InteractorFactory.getInteractorForHandle(menu);
            menuInteractor.uipress();
        end
        
        % Discouraged API
        function dismissAlert(actor)
            actor.dismissDialog('uialert');
        end
        
        function uilock(actor, bool)
            
            if strcmp(actor.Component.Visible, 'off')
                queueLockForInvisibleFigure(actor, bool)
                return;
            end
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uilock', 'Value', bool);
        end

        function chooseDialog(actor, dialogType, varargin)

            arguments
                actor (1,1)
                dialogType {mustBeTextScalar, mustBeMember(dialogType, {'uiconfirm', 'uialert'})}
            end

            arguments (Repeating)
                varargin
            end
            
            % get dialog interactor and call its method
            dialogInteractor = actor.getDialogInteractor(dialogType);
            dialogInteractor.chooseDialog(varargin{:});

        end

        function dismissDialog(actor, dialogType, varargin)

            arguments
                actor (1,1)
                dialogType {mustBeTextScalar, mustBeMember(dialogType, {'uiconfirm', 'uialert'})}
            end

            arguments (Repeating)
                varargin
            end
            
            % get dialog interactor and call its method
            dialogInteractor = actor.getDialogInteractor(dialogType);
            dialogInteractor.dismissDialog(varargin{:});

        end

    end
    
    methods (Access = private)
        
        function queueLockForInvisibleFigure(actor, bool)
            
            fig = actor.Component;
            
            cls = ?matlab.ui.Figure;
            prop = findobj(cls.PropertyList, 'Name', 'Visible');
            L = event.proplistener(fig, prop, 'PostSet', ...
                @(o,e)actor.doLockAndDeleteListener(bool));
            setappdata(fig, 'uilockListener', L);
        end
        
        function doLockAndDeleteListener(actor, bool)
            
            fig = actor.Component;
            rmappdata(fig, 'uilockListener');
            actor.uilock(bool)
        end
        
        function parser = parseInputs(actor, varargin)
            
            parser = inputParser;
            parser.addOptional("Position", missing, @(pos)validatePosition(actor, pos));
            parser.addParameter("SelectionType", "normal");
            % Button and Modifier are undocumented properties on press
            % API for supporting various click workflows and are subject to
            % change in future
            parser.addParameter("Button", "left");
            parser.addParameter("Modifier", []);
            parser.parse(varargin{:});

            if actor.checkIfSelectionTypeButtonModifierUsedTogether(parser)
                % Error out when both SelectionType and Button-Modifier
                % combinations are supplied due to ambiguity
                error(message('MATLAB:uiautomation:Driver:AmbiguousSelectionType'));
            end
        end

        function interactor = getDialogInteractor(actor, dialogtype)
            % Get dialog interactor based on the dialog type

            import matlab.unittest.internal.services.ServiceFactory;
            import matlab.automation.internal.services.ServiceLocator;
            
            liaison = matlab.uiautomation.internal.InteractorLookupLiaison;
            liaison.ComponentClass = string(dialogtype);
            namespace = "matlab.uiautomation.internal.interactors.dialogServices";
            locator = ServiceLocator.forNamespace(matlab.metadata.Namespace.fromName(namespace));
            serviceClass = ?matlab.uiautomation.internal.interactors.services.InteractorLookupService;
            locatedServiceClasses = locator.locate(serviceClass);
            locatedServices = ServiceFactory.create(locatedServiceClasses);
            fulfill(locatedServices, liaison);
            
            cls = liaison.InteractorClass;
            interactor = feval(str2func(cls.Name), actor);
        end
    end
end

function posArgs = getPositionArgs(position)
posArgs = {'X', position(1), 'Y', position(2)};
end