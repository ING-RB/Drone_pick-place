classdef LineSpecColor
%   This class is for internal use only. It may be removed in the future.

%LineSpecColor Defines the color for plannerLineSpec parameters.
%
%   obj = LineSpecColor() Returns the hash color code for the parameters in
%   plannerLineSpec based on the theme color of current axis fetched by
%   gca using Semantic Colors.

%   Copyright 2023 The MathWorks, Inc.

    properties (Dependent)
        % Properties are assigned dynamically based on current theme

        % States
        Start
        Goal
        State

        % Paths
        Path
        ReversePath
        OptimalPath

        % Trees
        Tree
        TreeState

        ReverseTree
        ReverseTreeState

        GoalTree
        GoalTreeState

        % Heading
        Heading
        HeadingFace

        Landmark
        Colliding
    end

    properties (Constant, Access = ?nav.algs.internal.InternalAccess)
        % Internal constant properties to define the semantic colors for the
        % parameters.

        % States
        StartInternal = nav.internal.SemanticColor.graphicColor(1,1);
        GoalInternal = nav.internal.SemanticColor.graphicColor(1,1);
        StateInternal = nav.internal.SemanticColor.graphicColor(1,4);

        % Paths
        PathInternal = nav.internal.SemanticColor.graphicColor(2,1);
        ReversePathInternal = nav.internal.SemanticColor.graphicColor(4,1);
        OptimalPathInternal = nav.internal.SemanticColor.graphicColor(1,1);

        % Trees
        TreeInternal = nav.internal.SemanticColor.graphicColor(2,2);
        TreeStateInternal = nav.internal.SemanticColor.graphicColor(2,2);

        ReverseTreeInternal = nav.internal.SemanticColor.graphicColor(4,4);
        ReverseTreeStateInternal = nav.internal.SemanticColor.graphicColor(4,4);

        GoalTreeInternal = nav.internal.SemanticColor.graphicColor(3,4);
        GoalTreeStateInternal = nav.internal.SemanticColor.graphicColor(3,4);

        % Heading
        HeadingInternal = nav.internal.SemanticColor.graphicColor(2,4);
        HeadingFaceInternal = nav.internal.SemanticColor.graphicColor(2,4);

        LandmarkInternal = nav.internal.SemanticColor.graphicColor(4,1);
        CollidingInternal = '--mw-color-error';

        % Clearance
        ClearanceInternal   = nav.internal.SemanticColor.graphicColor(7,1);
    end

    methods
        function obj = LineSpecColor()
        %LineSpecColor Default constructor
        end

        % Setter functions for the Dependent properties.

        function value = get.Start(obj)
        %Start Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.StartInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.Goal(obj)
        %Goal Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.GoalInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.State(obj)
        %State Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.StateInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.Path(obj)
        %Path Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.PathInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.OptimalPath(obj)
        %Path Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.OptimalPathInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.Landmark(obj)
        %Path Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.LandmarkInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.ReversePath(obj)
        %ReversePath Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.ReversePathInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.Tree(obj)
        %Tree Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.TreeInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.TreeState(obj)
        %TreeState Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.TreeStateInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.ReverseTree(obj)
        %ReverseTree Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.ReverseTreeInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.ReverseTreeState(obj)
        %ReverseTreeState Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.ReverseTreeStateInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.GoalTree(obj)
        %GoalTree Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.GoalTreeInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.GoalTreeState(obj)
        %GoalTreeState Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.GoalTreeStateInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.Heading(obj)
        %Heading Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.HeadingInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.HeadingFace(obj)
        %HeadingFace Returns color for parameter.

        % Semantic variable name of assigned color.
            name = obj.HeadingFaceInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end

        function value = get.Colliding(obj)
        %Colliding Returns color for objects in collision.

        % Semantic variable name of assigned color.
            name = obj.CollidingInternal;
            % Fetches hash code of semantic color.
            value = nav.internal.SemanticColor.semanticColor2hex(name);
        end
    end

    methods (Static)
        % Convenience methods to convert property names to color formats
        function name = semantic(propName)
        %semantic Returns semantic string for corresponding property name
            obj = nav.internal.LineSpecColor;
            name = obj.(string(propName) + "Internal");
        end
        function hex = hex(propName)
        %hex Returns hex code for corresponding property name
            obj = nav.internal.LineSpecColor;
            hex = nav.internal.SemanticColor.semanticColor2hex(obj.(string(propName) + "Internal"));
        end
        function rgb = rgb(propName)
        %rgb Returns 1x3 rgb value for corresponding property name
            obj = nav.internal.LineSpecColor;
            [~,rgb] = nav.internal.SemanticColor.semanticColor2hex(obj.(string(propName) + "Internal"));
        end
    end
end
