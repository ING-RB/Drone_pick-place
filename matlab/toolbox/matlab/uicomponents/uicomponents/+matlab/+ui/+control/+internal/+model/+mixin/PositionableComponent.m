classdef (Hidden) PositionableComponent < ...
        appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.ui.internal.mixin.Positionable & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer

    % This undocumented class may be removed in a future release.

    % This is a mixin parent class for all visual components that have the
    % 'Position', 'InnerPosition', 'OuterPosition' properties
    %
    % This class provides all implementation and storage for those
    % properties

    % Copyright 2011-2023 The MathWorks, Inc.

    properties(Dependent, AbortSet)
        %  InnerPosition - a four element vector, [left, bottom, width, height] of the inner art
        %                   InnerPosition is always interpreted in units 'pixels'.
        InnerPosition matlab.internal.datatype.matlab.graphics.datatype.Position = [100, 100, 20, 20];

        %  Position - an alias for InnerPosition for AppDesigner Components
        Position matlab.internal.datatype.matlab.graphics.datatype.Position = [100, 100, 20, 20];
    end

    properties(Dependent, SetAccess = 'private')

        %  OuterPosition - a four element vector, [left, bottom, width, height] of the outer art
        %             OuterPosition is interpreted in units 'pixels'.
        %             The user cannot set it, only read it.
        OuterPosition matlab.internal.datatype.matlab.graphics.datatype.Position = [100, 100, 20, 20];
    end

    properties (GetAccess = {...
            ?matlab.ui.control.internal.model.mixin.PositionableComponent,...
            ?matlab.ui.control.internal.controller.mixin.PositionableComponentController,...
            }, ...
            SetAccess = 'protected')
        % Whether the component has margins, i.e. OuterPosition can 
        % differ from OuterPosition
        HasMargins = false;
    end

    properties(	GetAccess = { ...
            ?matlab.ui.control.internal.controller.mixin.PositionPropertiesComponentController}, ...
            SetAccess = 'protected')
        %  AspectRatioLimits - a two element vector, representing the minimum
        %                   and the maximum value imposed on the ratio
        %                   width over height of the inner art.
        %
        %  Examples:
        %
        %  - The lamp imposes that the width should always be equal to the
        %	height, so the aspect ratio of the inner art has to satisfy:
        %	1 <= width/height <= 1, i.e. AspectRatioLimits = [1, 1]
        %
        % - The linear gauge in the horizontal orientation imposes that the
        %	width has to be at least twice the height, so the aspect ratio
        %	of the inner art has to satisfy: 2 <= width/height <= +Inf,
        %	i.e. AspectRatioLimits = [2, +Inf]
        %
        % - The button does not have any aspect ratio constraint, so the
        %	aspect ratio of the inner art has to satisfy:
        %	0 <= width/height <= +Inf, i.e. AspectRatioLimits = [0, +Inf]
        %
        % Access control:
        %
        % - The controller needs to have access to AspectRatioLimits to push
        % its value to the view. The App Designer needs the value to
        % show appropriate resize handles on each component.
        %
        % - A component overrides the default values in its constructor if
        % its defines aspect ratio constraints.
        % The AspectRatioLimits not be changed for a given component,
        % except after an orientation change. In that case, the component
        % should call the method updatePositionPropertiesAfterOrientationChange
        % which will take care of updating the AspectRatioLimits value.
        %
        AspectRatioLimits = [0, +Inf];

    end

    properties(	Dependent, GetAccess = {
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...
            ?matlab.ui.control.internal.model.mixin.PositionableComponent, ... Grant access to the children class
            ?matlab.graphics.mixin.ViewPropertiesManager...
            }, ...
            SetAccess = 'protected')
        % The abstract controller needs to have access to IsSizeFixed to push
        % its value to the view. The App Designer needs the value to
        % show appropriate resize handles on each component.
        %
        % Most components do not have a fixed width or height so the
        % default is set to [false false]. This property's SetAccess is made
        % 'protected' so that if a component (e.g. slider) has such
        % constraints, it will override the default values in its
        % constructor.

        % IsSizeFixed - Logical indicating whether Size is fixed
        % where Size = [Width, Height]
        %
        % Example:
        %
        %  - IsSizeFixed = [true false]
        %       indicates that the Width of the component is fixed and
        %       cannot be changed by the user
        %
        IsSizeFixed = [false false];

    end

    properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateInnerPosition matlab.internal.datatype.matlab.graphics.datatype.Position = [100, 100, 20, 20];

        PrivateOuterPosition matlab.internal.datatype.matlab.graphics.datatype.Position = [100, 100, 20, 20];

    end

    properties(Access = 'private')
        % AdjustInnerSizeFcn - Strategy function for how size reacts
        % to Position property changes
        %
        % Controlled by the IsSizeFixed property
        %
        AdjustInnerSizeFcn = @adjustInnerSizeEnforceAspectRatioConstraints;
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods

        % -----------------------------------------------------------------
        % Getter/setter for InnerPosition
        % -----------------------------------------------------------------
        function set.InnerPosition(obj, newInnerPosition)
            % If Position set is not allowed (e.g. in Layout container)
            % then a warning will be shown
            if (~obj.doSetPositionValidation())
                return;
            end

            % Error checking done via datatype specification

            % Adjust the new inner size given the size constraints
            newInnerSize = obj.AdjustInnerSizeFcn(obj, obj.PrivateInnerPosition, newInnerPosition);
            newInnerPosition(3:4) = newInnerSize;

            % Store the previous InnerPosition
            oldInnerPosition = obj.PrivateInnerPosition;

            % Set property
            obj.PrivateInnerPosition = newInnerPosition;

            % Update PrivateOuterPosition
            delta = newInnerPosition - oldInnerPosition;
            newOuterPosition = obj.OuterPosition + delta;

            % Make sure width and height are postive numbers.
            % When the Position is set repeatedly, there can be delays in
            % the update of the outer size from the client side, thus
            % causing the inner and outer to be out-of-sync, resulting in
            % the estimated width/height to be negative. g2133744
            obj.PrivateOuterPosition = [newOuterPosition(1:2), max([0,0], newOuterPosition(3:4))];

            % Push OuterPosition to the view as well.
            %
            % Reasons:
            %
            % 1) Performance
            % The estimated OuterPosition is accurate for components with
            % no margins, so this will avoid needing the client side
            % to send the value back to the server (and thus improve
            % performance).
            % The downside is that for components with margins, this
            % estimated OuterPosition is not correct and the client side 
            % now needs to process this incorrect value (later, the correct
            % one will override it).
            % Since the majority of the components are with no margins,
            % sending OuterPosition yields a better performance overall.
            %
            % 2) Lazy loading
            % Marking dirty OuterPosition along with InnerPosition to client  
            % because o/w the cache will send the OuterPosition default
            % value instead of the model value to the client side. With lazy 
            % loading, OuterPosition is not updated until the view is
            % created, so auto resize will get the default OuterPosition
            % instead of an estimated value (closer to the correct value
            % than the default)
            obj.markPropertiesDirty({'InnerPosition', 'OuterPosition'});
        end

        function innerPosition = get.InnerPosition(obj)
            innerPosition = obj.PrivateInnerPosition;
        end

        % -----------------------------------------------------------------
        % Getter for OuterPosition
        % -----------------------------------------------------------------

        function outerPosition = get.OuterPosition(obj)
            outerPosition = obj.PrivateOuterPosition;
        end

        % -----------------------------------------------------------------
        % Getter/setter for Position
        % -----------------------------------------------------------------

        function set.Position(obj, newPosition)
            % Position is an alias for InnerPosition for AppDesigner components
            obj.InnerPosition = newPosition;
        end

        function position = get.Position(obj)
            position = obj.PrivateInnerPosition;
        end

        % -----------------------------------------------------------------
        % Getter/setter for IsSizeFixed
        % -----------------------------------------------------------------

        function set.IsSizeFixed(obj, newIsSizeFixed)
            arguments
                obj matlab.ui.control.internal.model.mixin.PositionableComponent
                newIsSizeFixed (1,2) logical
            end
            if(newIsSizeFixed(1) == false && newIsSizeFixed(2) == false)
                obj.AdjustInnerSizeFcn = @adjustInnerSizeEnforceAspectRatioConstraints;
            elseif(newIsSizeFixed(1) == true)
                % Fixed width
                obj.AdjustInnerSizeFcn = @adjustInnerSizeFixWidth;
            elseif(newIsSizeFixed(2) == true)
                % Fixed height
                obj.AdjustInnerSizeFcn = @adjustInnerSizeFixHeight;
            end
        end

        function isSizeFixed = get.IsSizeFixed(obj)
            switch char(obj.AdjustInnerSizeFcn)
            case 'adjustInnerSizeFixWidth'
                isSizeFixed = [true false];
            case 'adjustInnerSizeFixHeight'
                isSizeFixed = [false true];
            otherwise
                isSizeFixed = [false false];
            end
        end

    end


    % -----------------------------------------------------------------
    % Helper methods for setters
    % -----------------------------------------------------------------
    methods (Access='private')
        function handleComponentResized(obj, newInnerPosition, newOuterPosition)
            % The method is accessed by the controller when the view sends
            % in the actual values for size, location, outersize,
            % outerlocation (e.g. when a state label is changed).
            %
            % - Update the private properties with the new values.
            % Do not use the public setters because those values are
            % coming from the view (i.e. truth for positioning). Using the
            % public setters would trigger estimation of the outer based on
            % the values of the inner art, yielding incorrect messages back
            % to the view
            %
            % - Do not explicitly mark the properties dirty, as the
            % properties are coming from the Peer Node already.  There is
            % no need to re-push the values back to the view.  Doing so can
            % even create a race condition and cause the component to jump
            % (g1045422)
            %
            % - In the case where only Size/Location (not OuterSize/
            % OuterLocation) are received, we considered updating the outer
            % art with estimated values so the OuterPosition remains
            % reasonable wrt InnerPosition.
            % However, we could not because the estimation assumed that the
            % inner art is always smaller than the outer art, but
            % there are cases where they can get out of sync, which results
            % in negative estimated width/height of the outer art.
            % An example is: Create a component and change the orientation
            % right after. The client first comes back with the exact values for
            % the outer art -before orientation change- (latency), while
            % the private inner art is -after orientation change-
            % (server side estimation following orientation change).

            % Set the private properties to prevent infite loops of updates
            % and prevent component from jumping (see comments above)
            if (obj.HasMargins)
                obj.PrivateInnerPosition = newInnerPosition;
                obj.PrivateOuterPosition = newOuterPosition;
            else
                % For components with no margins (e.g. button, edit field), 
                % OuterPosition must always match InnerPosition. 
                % OuterPosition is not expected to be sent from the client
                % side for performance reasons (avoids unncessary event
                % processing)
                obj.PrivateInnerPosition = newInnerPosition;
                obj.PrivateOuterPosition = newInnerPosition;
            end

        end

    end


    % ---------------------------------------------------------------------
    % Functions accessible by the controller
    % ---------------------------------------------------------------------
    methods (Access = {...
            ?matlab.ui.internal.mixin.ConcretePositionable, ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?matlab.ui.control.internal.controller.mixin.PositionableComponentController, ...
            ?matlab.ui.internal.componentframework.services.optional.PositionBehaviorAddOn, ...
            ?matlab.ui.control.internal.model.mixin.PositionableCompatibleComponent, ...
            ?matlab.ui.control.internal.model.mixin.PositionableComponent,...
            ?matlab.ui.control.ClientComponent,...
            ?matlab.ui.internal.controller.uicontrol.UIControlController
            })

        function setPositionFromClient(obj, ~, newInnerPosition, newOuterPosition)
            % This method guarantees a standard interface to be used by the
            % PositionableComponentController for both, those HMI/Standard
            % components that have already been transitioned to use GBT
            % position implementation, and for those that have not.
            obj.handleComponentResized(newInnerPosition, newOuterPosition);
        end

    end
    methods (Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?matlab.ui.control.internal.controller.mixin.PositionableComponentController, ...
            })

        function handleOrientationChanged(obj, newOrientation)
            % The method is accessed by the controller when the view sends
            % notification of an Orientation changing.
            %
            % When Orientation is changed, update the private property
            % because the public setters tries to estimate new values for
            % the size/location of the inner and outer arts.
            % The actual values are being sent by the view and will be
            % updated on the component separately

            obj.PrivateOrientation = newOrientation;
        end

        function handleAspectRatioLimitsChange(obj, newAspectRatioLimits)
            obj.AspectRatioLimits = newAspectRatioLimits;

        end

        function handleIsSizeFixedChange(obj, newIsSizeFixed)
            obj.IsSizeFixed = newIsSizeFixed;
        end

    end


    % ---------------------------------------------------------------------
    % Functions accessible by child classes
    % ---------------------------------------------------------------------
    methods (Access = 'protected')


        function updatePositionPropertiesAfterOrientationChange(obj, ...
                oldOrientation, newOrientation)
            % When orientation changes from horizontal to vertical, or
            % vice versa:
            % - flip the size of the inner art because the form factor of horizontal is
            % extra wide vs vertical form factor is extra long
            %
            % - estimate the size of the outer art.
            % by default, flip the width and height of the outer art, like
            % we do for the inner art.
            % Components have the option to provide a better estimate by
            % overridding the method estimateOuterPositionAfterOrientationChange
            %
            % - flip and inverse AspectRatioLimits

            if(strcmpi(newOrientation, oldOrientation))
                % the following is only applicable if the orientation did
                % change
                return;
            end

            % Store the old inner size
            oldInnerSize = obj.InnerPosition(3:4);

            % Flip the width and height of the inner art
            obj.PrivateInnerPosition = obj.InnerPosition([1,2,4,3]);

            % Estimate the new outer art
            obj.PrivateOuterPosition = obj.estimateOuterPositionAfterOrientationChange(...
                oldOrientation, newOrientation, oldInnerSize);

			% When orientation changes from horizontal to vertical, or
			% vice versa, AspectRatioLimits and IsSizeFixed are updated
			obj.updateSizeConstraints();

        end

        function [newOuterPosition] = estimateOuterPositionAfterOrientationChange(...
                obj, oldOrientation, newOrientation, oldInnerSize)
            % Returns an estimate of the outer art after an orientation
            % change
            %
            % By default, simply flip the width and height of the outer art
            % A component can override this method to provide a better
            % estimate if needed. For example, the switches do, the
            % estimation accounts for how the labels display in the
            % vertical vs horizontal direction

            newOuterPosition = obj.OuterPosition([1,2,4,3]);
        end

        function updateSizeConstraints(obj)
            % This method is used to update AspectRatioLimits and IsSizeFixed
            % when the orientation of the component is changed:
            % - from horizontal to vertical, or vice versa (e.g. linear
            % gauge, all the switches)
            % - from (south or north) to (east or west), or vice versa
            % (e.g. semi-circular gauge).
            % When orientation changes in the cases above, the width and
            % height before the orientation change become the height and
            % width, respectively, after the orientation change.

            % The aspect ratio constraints are flipped and inversed
            oldLimits = obj.AspectRatioLimits;
            newLimits = 1./oldLimits([2 1]);
            obj.AspectRatioLimits = newLimits;

            % The property IsSizeFixed is flipped left-right
            obj.IsSizeFixed = obj.IsSizeFixed([2 1]);

        end

    end

end


% -------------------------------------------------------------------------
% Helper functions
% -------------------------------------------------------------------------

function [newWidth, newHeight] = updateSizeToSatisfyAspectRatioConstraints(...
    width, height, aspectRatioLimits)
    % Returns new width and height values that satisfy the aspect ratio
    % constraints if the provided width and height values do not.
    % If the provided width and height do satisfy the aspect ratio
    % constraints, return them unchanged.

    if(height == 0)
        aspectRatio = Inf;
    else
        aspectRatio = width/height;
    end

    % aspect ratio constraints
    minAspectRatio = aspectRatioLimits(1);
    maxAspectRatio = aspectRatioLimits(2);

    if(aspectRatio >= minAspectRatio && aspectRatio <= maxAspectRatio)
        % The width and height satisfy the aspect ratio constraints,
        % return them unchanged
        newWidth = width;
        newHeight = height;

    elseif (aspectRatio < minAspectRatio )
        % The aspect ratio is less than the minimum allowed.
        % Use the minimum aspect ratio to calculte the new height and keep
        % the width unchanged

        % Use the min aspect ratio to determine the new values
        validAspectRatio = minAspectRatio;

        newWidth = width;
        newHeight = newWidth / validAspectRatio;

    elseif (aspectRatio > maxAspectRatio)
        % The aspect ratio is greater than the maximum allowed.
        % Use the maximum aspect ratio to calculte the new width and keep
        % the height unchanged

        % Use the max aspect ratio to determine the new values
        validAspectRatio = maxAspectRatio;

        newHeight = height;
        newWidth = newHeight * validAspectRatio;

    end

end

% Ignore round off errors when comparing doubles with integer
% in the context of a uicontrol slider.
function nearlyEqual = isNearlyEqual(dim1, dim2)
    assert(isscalar(dim1)); 
    assert(isscalar(dim2));
    
    if isequal(dim1, dim2)
        nearlyEqual = true; 
        return;
    else 
        nearlyEqual = (abs(dim1 - dim2) < 1000*eps);
    end
end

function adjustedInnerSize = adjustInnerSizeEnforceAspectRatioConstraints(component, oldInnerPosition, newInnerPosition)
    %ADJUSTINNERSIZEENFORCEASPECTRATIOCONSTRAINTS - Inner size strategy function that enforces AspectRatioLimits
    %on the width and height of a new Position value
    %
    % Given the new requested InnerPosition, return a value for the new size
    % that will satisfy the size constraints defined by the component
    % Neither the width or height is constrained to be fixed

    % store the previous Size
    oldWidth = oldInnerPosition(3);
    oldHeight = oldInnerPosition(4);

    newWidth = newInnerPosition(3);
    newHeight = newInnerPosition(4);

    % Verify that the width and height satisfy the aspect ratio
    % constraints. If they don't, adjust them so they do
    [adjustedWidth, adjustedHeight] = updateSizeToSatisfyAspectRatioConstraints(...
        newWidth, newHeight, component.AspectRatioLimits);

    % Throw warning if there is no change in size. g1321058
    if(isequal(adjustedWidth, oldWidth) && isequal(adjustedHeight, oldHeight))
        % Size did not change

        if(isequal(newWidth, oldWidth) && ~isequal(newHeight, oldHeight))
            % User requested new height, throw appropriate
            % warning
            msgTxt = getString(message('MATLAB:ui:components:noSizeChangeForRequestedHeight'));
            % Last section of the warningId
            mnemonicField = 'noSizeChangeForRequestedHeight';
            % Display warning
            matlab.ui.control.internal.model.PropertyHandling.displayWarning(component, mnemonicField, msgTxt);

        elseif(~isequal(newWidth, oldWidth) && isequal(newHeight, oldHeight))
            % User request new width, throw appropriate warning
            msgTxt = getString(message('MATLAB:ui:components:noSizeChangeForRequestedWidth'));
            % Last section of the warningId
            mnemonicField = 'noSizeChangeForRequestedWidth';
            % Display warning
            matlab.ui.control.internal.model.PropertyHandling.displayWarning(component, mnemonicField, msgTxt);
        end
    end

    adjustedInnerSize = [adjustedWidth, adjustedHeight];
end

function adjustedInnerSize = adjustInnerSizeFixWidth(component, oldInnerPosition, newInnerPosition)
    %ADJUSTINNERSIZEFIXWIDTH - Inner size strategy function that never changes the width of a component
    %
    % Given the new requested InnerPosition, return a value for the new size
    % that will satisfy the size constraints defined by the component

    % store the previous Size
    oldWidth = oldInnerPosition(3);
    oldHeight = oldInnerPosition(4);

    newWidth = newInnerPosition(3);
    newHeight = newInnerPosition(4);

    % The width cannot be changed, keep the old value
    adjustedWidth = oldWidth;
    % Requested height is honored
    adjustedHeight = newHeight;

    % Throw warning if user tried to change width. g1321058
    if(~isNearlyEqual(adjustedWidth, newWidth))
        msgTxt = getString(message('MATLAB:ui:components:fixedWidth'));
        % Last section of the warningId
        mnemonicField = 'fixedWidth';
        % Display warning
        matlab.ui.control.internal.model.PropertyHandling.displayWarning(component, mnemonicField, msgTxt);
    end

    adjustedInnerSize = [adjustedWidth, adjustedHeight];
end

function adjustedInnerSize = adjustInnerSizeFixHeight(component, oldInnerPosition, newInnerPosition)
    %ADJUSTINNERSIZEFIXHEIGHT - Inner size strategy function that never changes the height of a component
    %
    % Given the new requested InnerPosition, return a value for the new size
    % that will satisfy the size constraints defined by the component

    % store the previous Size
    oldWidth = oldInnerPosition(3);
    oldHeight = oldInnerPosition(4);

    newWidth = newInnerPosition(3);
    newHeight = newInnerPosition(4);

    % The height cannot be changed, keep the old value
    adjustedHeight = oldHeight;
    % Requested width is honored
    adjustedWidth = newWidth;

    % Throw warning if user tried to change height. g1321058
    if(~isNearlyEqual(adjustedHeight, newHeight))
        msgTxt = getString(message('MATLAB:ui:components:fixedHeight'));
        % Last section of the warningId
        mnemonicField = 'fixedHeight';
        % Display warning
        matlab.ui.control.internal.model.PropertyHandling.displayWarning(component, mnemonicField, msgTxt);
    end

    adjustedInnerSize = [adjustedWidth, adjustedHeight];
end
