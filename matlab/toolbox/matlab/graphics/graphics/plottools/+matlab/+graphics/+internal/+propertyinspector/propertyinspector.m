function propertyinspector(action,varargin)
% propertyinspector function can be called to show/hide/toggle property
% inspector

%    FOR INTERNAL USE ONLY -- This function is intentionally undocumented
%    and is intended for use only with the scope of function in the MATLAB
%    Engine APIs.  Its behavior may change, or the function itself may be
%    removed in a future release.

% Copyright 2017-2024 The MathWorks, Inc.

switch lower(action)
    case 'toggle'
        % If the inspector window is already showing, then close the
        % inspector and exit out of plotedit mode
        if com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.isInspectorVisible
            matlab.graphics.internal.propertyinspector.propertyinspector('hide');
        else
            matlab.graphics.internal.propertyinspector.propertyinspector('show');
        end
    case 'show'
        % If no parameters are passed to the 'show'. Then, create/use the
        % current figure and enable plot-edit mode and select the default
        % object. If inspector already exists, then just bring it to the
        % front. If the inspect(obj) is called with a parameter, then use
        % the object and figure out the ancestor figure as before.
        if nargin < 2
            % Get/Create the current Figure
            figureHandles = gcf;
            % Use the axes as the default object. If there is no current
            % axes, then use figure as the default object.
            if ~isempty(figureHandles.CurrentAxes)
                hObjs = figureHandles.CurrentAxes;
            else
                hObjs = figureHandles;
            end

            if isactiveuimode(figureHandles,'Standard.EditPlot')
                hMode = getuimode(figureHandles,'Standard.EditPlot');
                if ~isempty(hMode)
                    hObjs = hMode.ModeStateData.PlotSelectMode.ModeStateData.SelectedObjects;
                end
            end
            indexByFigure = ones(size(hObjs));
        else
            % For multiple objects, hObjs can be a cell array. The
            % assumption is that hObjs will always have the same length as
            % indexByFigure. It will be possible to index to hObjs array
            % using indexByFigure
            hObjs = varargin{1};
            if iscell(hObjs)
                % Get the graphics array
                hObjs = [hObjs{:}];
            end

            % Call the inspector helper method, as this not only checks
            % isgraphics(), but also handles objects like DataTipTemplate, which
            % isgraphics() is false, but is inspectable as part of the figure
            % hierarchy (and has an ancestor).
            if internal.matlab.inspector.Utils.isAllGraphics(hObjs)
                hFig = ancestor(hObjs,'figure');
                if iscell(hFig)
                    hFig = [hFig{:}];
                end
            else
                hFig = [];
            end
            % Find the unique figures in the figure array. ic is used to
            % index onto the object array to find out which object(s) belong
            % to a certain figure
            [figureHandles,~,indexByFigure] = unique(hFig);
        end

        %Do not show the inspector for Live Editor figures
        import matlab.internal.editor.figure.*;
        isLiveEditorFigure = any(arrayfun(@(fig) FigureUtils.isEditorEmbeddedFigure(fig) ||...
            FigureUtils.isEditorSnapshotFigure(fig), figureHandles));

        if isLiveEditorFigure
		    msgbox(getString(message('MATLAB:propertyinspector:LiveEditorExclusion')), ....
	           getString(message('MATLAB:propertyinspector:InspectorTitle')),'modal')
            return
        end

        % If the platform is unsupported to show the new JS Inspector such
        % as MATLAB Online, then just show old java inspector and early
        % return g1738295. We also need to ensure if figure needs to be
        % morphed, currently, web figures are morphed when showing property
        % inspector - Java inspector shows up in these cases.
        if ~matlab.graphics.internal.propertyinspector.shouldShowNewInspector(hObjs)
            % Calling inspect will take care of invoking Java Inspector
            % with the correct parameters
            inspect(hObjs);
            return;
        end

        % Make sure no inspector listeners get fired while inspect function
        % is executing
        hInspectorMgnr = matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance();        
        
        if matlab.graphics.internal.propertyinspector.shouldShowEmbeddedInspector(figureHandles)
            hInspectorMgnr = matlab.graphics.internal.propertyinspector.EmbeddedInspectorManager.getInstance();
        end
        hInspectorMgnr.temporarilyStopInspectorListeners(); 

        % Show the inspector immediately.  Object selection can happen as it is
        % opening.
        hInspectorMgnr.showInspector(hObjs);

        % Loop through all the unique figures and select the objects
        % belonging to each figure - g1695899
        if numel(figureHandles) > 0
            for i=1:numel(figureHandles)
                iFig = figureHandles(i);
                if isa(hObjs,'matlab.mixin.internal.Scalar')
                    %1981504 - we cant index into an Scalar object
                    iObj = hObjs;
                else
                    iObj = hObjs(indexByFigure==i);
                end
                % Enable plotedit mode if its not a uifigure and object's plotedit
                % mode is off.
                % TODO: In future, if we have menubar or toolbar in
                % uifigure, we can remove this check for figure being a
                % uifigure.
                if ~isempty(iFig) && isvalid(iFig) && ~matlab.ui.internal.FigureServices.isUIFigure(iFig)
                    % Select the object prior to turning on plot edit, otherwise
                    % the selection change will cause the axes to be inspected
                    % first, and then the object being inspected.
                    matlab.graphics.internal.drawnow.callback(@(~,~) localSelectObject(iObj));

                    % For non selectable objects it is safe to call
                    % selectobject.
                    if ~isactiveuimode(iFig,'Standard.EditPlot')
                        matlab.graphics.internal.drawnow.callback(@(~,~) localActivatePlotEdit(iFig));

                        % when inspect(axes) is called, force drawnow so that
                        % inspector positioning logic can work
                    end
                end
            end
        end
        
    case 'hide'
        % Hide should close both java inspector and the new Javascript
        % Inspector if needed g1738295
        if usejava('jvm')
			com.mathworks.mlservices.MLInspectorServices.closeWindow;
        end
        
        if matlab.graphics.internal.propertyinspector.shouldShowNewInspector()		

            fig = get(groot, 'CurrentFigure');

            if ~isempty(fig) && strcmpi(get(fig,'DefaultTools'), "toolstrip")
                matlab.graphics.internal.toolstrip.inspectorHelper(fig, false);                
            else
                hInspectorMgnr = matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance();
                hInspectorMgnr.closePropertyInspector();
            end
        end
    case 'initinspector'
        if ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.showJavaInspector
            matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance();
        end
    case 'openandrestoreinspector'
        % restore the auto behavior for the inspector window if showing JS
        % Inspector window. Needed when you click on Inspector button
        if ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.showJavaInspector
            com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.restoreToDefault();
        end
        matlab.graphics.internal.propertyinspector.propertyinspector('show');
end
end

function localActivatePlotEdit(iFig)
if ~isempty(iFig)
    if all(arrayfun(@(h) isvalid(h) && (~isa(h,'matlab.graphics.internal.GraphicsCoreProperties')...
            || strcmp(h.BeingDeleted,'off')),iFig))
        plotedit(iFig,'on')
    end
end
end

function localSelectObject(iObj)
iObj = handle(iObj);
if ~isempty(iObj)
    if all(arrayfun(@(h) isvalid(h) && (~isa(h,'matlab.graphics.internal.GraphicsCoreProperties')...
            || strcmp(h.BeingDeleted,'off')),iObj, "ErrorHandler", @(~,~) false))
        selectobject(iObj,'replace')
    end
end
end
