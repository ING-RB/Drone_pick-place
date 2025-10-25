classdef plannerLineSpec
%plannerLineSpec class for plotting path planner outputs
%
%   plannerLineSpec methods: Static methods for specifying color, line, and
%   marker properties to plot path planner outputs.
%      start       - Specifications for plotting start state
%      goal        - Specifications for plotting goal state
%      path        - Specifications for plotting forward path
%      reversePath - Specifications for plotting reverse path
%      tree        - Specifications for plotting forward search tree
%      goalTree    - Specifications for plotting search tree from
%                    goal to start
%      reverseTree - Specifications for plotting reverse search tree
%      state       - Specifications for plotting generic states
%      heading     - Specifications for plotting heading angle
%

%   Copyright 2023 The MathWorks, Inc.


    properties (Constant,Access = private)
        % LineSpec parameters to be set for each entity.
        featureProp = {'Color','LineStyle','LineWidth','Marker','MarkerSize',...
                       'MarkerEdgeColor','MarkerFaceColor','DisplayName'};
    end

    methods (Access = private)
        function obj =  plannerLineSpec()
        end
    end

    methods (Static)
        % Functions to set the default parameters for each entity

        function [valCell, valStruct] = start(varargin)
        %

        %start Set LineSpec parameters for 'Start'
            narginchk(0,16);
            funcName = 'start';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.Start,Marker.None,Size.Default,...
                          Marker.Square,Size.Start,Color.Start,Color.Start,'Start'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = goal(varargin)
        %

        %goal Set LineSpec parameters for 'Goal'
            narginchk(0,16);
            funcName = 'goal';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.Goal,Marker.None,Size.Default,...
                          Marker.Star,Size.Goal,Color.Goal,Color.Goal,'Goal'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = state(varargin)
        %

        %state Set LineSpec parameters for 'State'
            narginchk(0,16);
            funcName = 'state';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.State,Marker.None,Size.Default,...
                          Marker.Circle,Size.State,Color.State,Color.State,'State'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = path(varargin)
        %

        %path Set LineSpec parameters for 'Path'
            narginchk(0,16);
            funcName = 'path';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.Path,Marker.Line,Size.Path,Marker.Point,...
                          Size.PathState,Color.Path,Color.Path,'Path'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = reversePath(varargin)
        %

        %reversePath Set LineSpec parameters for 'Reverse Path'
            narginchk(0,16);
            funcName = 'reversePath';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.ReversePath,Marker.Line,Size.Path,Marker.Point,...
                          Size.PathState,Color.ReversePath,Color.ReversePath,'Reverse Path'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = tree(varargin)
        %

        %tree Set LineSpec parameters for 'Tree'
            narginchk(0,16);
            funcName = 'tree';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.Tree,Marker.Line,Size.Default,Marker.Point,...
                          Size.TreeState,Color.TreeState,Color.TreeState,'Tree'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = goalTree(varargin)
        %

        %goalTree Set LineSpec parameters for 'Goal Tree'
            narginchk(0,16);
            funcName = 'goalTree';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.GoalTree,Marker.Line,Size.Default,Marker.Point,...
                          Size.TreeState,Color.GoalTreeState,Color.GoalTreeState,'Goal Tree'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = reverseTree(varargin)
        %

        %reverseTree Set LineSpec parameters for 'Reverse Tree'
            narginchk(0,16);
            funcName = 'reverseTree';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.ReverseTree,Marker.Line,Size.Default,...
                          Marker.Point,Size.TreeState,Color.ReverseTreeState,...
                          Color.ReverseTreeState,'Reverse Tree'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end

        function [valCell, valStruct] = heading(varargin)
        %

        %heading Set LineSpec parameters for 'Heading'
            narginchk(0,16);
            funcName = 'heading';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.Heading,Marker.Line,Size.State,...
                          Marker.Circle   ,Size.State,Color.Heading,Color.HeadingFace,'Heading'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end
    end

    methods(Access= private,Static)

        function [c,m,s] = fetchProperties()
        %fetchProperties Will return the available color, marker and size options objects.
            c = nav.internal.LineSpecColor;
            m = nav.internal.Marker;
            s = nav.internal.Size;
        end

        function [propsCell,propsStruct] = getCellStruct(val,funcName,varargin)
        %getCellStruct Converts to cell array which can be fed to plot()
        %and struct for visible validations
            propsDefault = cell2struct(val,plannerLineSpec.featureProp,2);

            % Parse name-value pair inputs and return struct containing
            % properties
            props = coder.internal.parseParameterInputs(propsDefault, struct(), varargin{:});
            propsStruct = coder.internal.vararginToStruct(props, propsDefault, varargin{:});

            % Validate size parameters.
            plannerLineSpec.validateSizeParam(propsStruct.LineWidth,funcName,'LineWidth');
            plannerLineSpec.validateSizeParam(propsStruct.MarkerSize,funcName,'MarkerSize');

            % Validate Marker/LineStyle type
            plannerLineSpec.validateMarker(propsStruct.Marker,funcName,'Marker');
            plannerLineSpec.validateMarker(propsStruct.LineStyle,funcName,'LineStyle');

            % Validate Color
            validatecolor(propsStruct.Color);
            validatecolor(propsStruct.MarkerEdgeColor);
            validatecolor(propsStruct.MarkerFaceColor);

            % Validate Display Name
            plannerLineSpec.validateDisplayName(propsStruct.DisplayName,funcName,'DisplayName')

            propsCell = reshape([plannerLineSpec.featureProp;struct2cell(propsStruct)'],1,[]);
        end

        function validateSizeParam(val,funcName,varName)
        % validateSizeParam Validates size parameter to be positive value.
            validateattributes(val,'numeric', ...
                               {'scalar','nonempty','finite','positive'}, ...
                               funcName,varName);
        end

        function validateDisplayName(val,funcName,varName)
        % validateDisplayName Validates DisplayName parameter to be string.
            validateattributes(val,{'string','char'},{'scalartext'}, ...
                               funcName,varName);
        end

        function validateMarker(val,funcName,varName)
        %validateMarker Validates marker or line type.
        %
        %   Various line types, plot markers may be used with LineSpec
        %   where val is a character string made from one element
        %   from any or all the following 2 columns:
        %
        %   .     point              -     solid
        %   o     circle             :     dotted
        %   x     x-mark             -.    dash dot
        %   +     plus               --    dashed
        %   *     star             (none)  no line
        %   s     square
        %   d     diamond
        %   v     triangle (down)
        %   ^     triangle (up)
        %   <     triangle (left)
        %   >     triangle (right)
        %   p     pentagram
        %   h     hexagram

            if(strcmp(varName,'Marker'))
                validString = {'.','o','x','*','square','diamond','v','^','<','>','pentagram','hexagram'};
            else
                validString = {'-','--',':','-.','none'};
            end
            validatestring(val,validString,funcName,varName);
        end
    end

    methods(Static, Access = {?nav.algs.internal.FactorGraphVisualization})
        function [valCell, valStruct] = landmark(varargin)
        %

        %path Set LineSpec parameters for 'Landmark'
            narginchk(0,16);
            funcName = 'landmark';
            % Objects of LineSpec params
            [Color,Marker,Size] = plannerLineSpec.fetchProperties;
            % Default values
            defaultVal = {Color.Landmark,Marker.Line,Size.Path,Marker.Point,...
                          Size.PathState,Color.Landmark,Color.Landmark,'Landmark'};
            % Parse inputs
            [valCell, valStruct] = plannerLineSpec.getCellStruct(defaultVal,funcName,varargin{:});
        end
    end
end

