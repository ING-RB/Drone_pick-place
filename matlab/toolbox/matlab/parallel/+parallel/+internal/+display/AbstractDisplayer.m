% AbstractDisplayer - base class for displayers for both Cluster
%    and request queues. Manages the actual and expected classes
%    of the objects to be displayed.

% Copyright 2013-2023 The MathWorks, Inc.

classdef (Hidden) AbstractDisplayer < handle
    properties ( Constant, GetAccess = protected )
        DeletedString = 'deleted';
    end
    properties (GetAccess = protected, SetAccess = immutable)
        Class
        ClassDisplayName
        RequiredType
    end
    properties (Abstract, SetAccess = immutable, GetAccess = protected)
        DisplayHelper
    end
    properties (GetAccess = protected, SetAccess = immutable, Dependent)
        ShowLinks
    end
    methods
        function tf = get.ShowLinks(~)
            tf = matlab.internal.display.isHot;
        end
        function obj = AbstractDisplayer(className, requiredType)
            obj.Class            = className;
            obj.RequiredType     = requiredType;
            obj.ClassDisplayName = regexprep(requiredType, '.*\.', '');
        end
        function doDisplay(obj, toDisp, name)
            obj.errorIfWrongType(toDisp);
            obj.displayInputName(name);
            obj.doDisp(toDisp);
        end
        function doDisp(obj, toDisp)
            import parallel.internal.display.AbstractDisplayer
            
            obj.errorIfWrongType(toDisp);
            if isempty(toDisp)
                obj.displayEmptyObject(toDisp);
            elseif isscalar(toDisp)
                obj.doSingleDisplay(toDisp);
            else
                obj.doVectorDisplay(toDisp);
            end
            AbstractDisplayer.printNewlineIfLoose();
        end
    end
    methods (Sealed, Access = protected)
        function errorIfWrongType(obj, toDisp)
            if ~isa(toDisp, obj.RequiredType)
                error(message('MATLAB:parallel:display:ExpectedDifferentType', ...
                              obj.RequiredType, class(toDisp)));
            end
        end
        function displayEmptyObject(obj, toDisp)
            dimensionString = obj.DisplayHelper.formatEmptyDimension(...
                size(toDisp), obj.formatDocLink(obj.Class));
            fprintf('%s\n', dimensionString);
        end

        function classDocLink = formatDocLink(obj, fullyQualifiedClassNameString)
            displayNameArray = regexp(fullyQualifiedClassNameString, '\.', 'split');
            displayName = displayNameArray{end};

            if obj.ShowLinks
                % Use the specific subclass name to build the hyperlink to
                % class documentation if we haven't been told otherwise
                classDocLink = sprintf('<a href="matlab: helpPopup %s" style="font-weight:bold">%s</a>', ...
                                       fullyQualifiedClassNameString, displayName);
            else
                classDocLink = displayName;
            end
        end
    end

    methods (Sealed, Static, Access = protected)
        function displayInputName(name)
            import parallel.internal.display.AbstractDisplayer

            AbstractDisplayer.printNewlineIfLoose();
            if isempty(name)
                fprintf('ans = \n');
            else
                fprintf('%s = \n', name);
            end
            AbstractDisplayer.printNewlineIfLoose();
        end
        function printNewlineIfLoose()
            if strcmp(matlab.internal.display.formatSpacing(), 'loose')
                fprintf('\n');
            end
        end
    end

    methods (Abstract, Access = protected)
        doSingleDisplay(obj, toDisp)
        doVectorDisplay(obj, toDisp)
    end
end
