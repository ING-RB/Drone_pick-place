function [treeComponent, varargout] = uitree(varargin)
%UITREE Create  standard tree or check box tree component 
%   t = UITREE creates a standard tree in a new figure and returns the Tree
%   object. MATLAB calls the uifigure function to create the figure.
%
%   t = UITREE(style) creates a tree of the specified style. Specify style
%   as 'checkbox' to create a check box tree instead of a standard one.
%
%   t = UITREE(parent) creates a standard tree in the specified parent
%   container. The parent can be a figure created using the uifigure
%   function, or one of its child containers: Tab, Panel, or ButtonGroup.
%
%   t = UITREE(parent,style) creates a tree of the specified style in the
%   specified parent container.
%
%   t = UITREE(___, Name,Value) creates a tree with properties specified by
%   one or more Name,Value pair arguments. Use this option with any of the
%   input arguments combinations in the previous syntaxes.
%
%   Tree supported functions:
%      collapse           - Collapse tree node
%      expand             - Expand tree node
%      scroll             - Scroll to location within tree
%      addStyle           - Add style to tree
%      removeStyle        - Remove style from tree
%
%   Example 1: Tree with Nested Nodes
%      f = uifigure;
%      tr = uitree(f);
%
%      % Assign Tree callback in response to node selection
%      tr.SelectionChangedFcn = @(src, event)display(event);
%
%      % First level nodes
%      category1 = uitreenode(tr,'Text','Runners','NodeData',[]);
%      category2 = uitreenode(tr,'Text','Cyclists','NodeData',[]);
%
%      % Second level nodes.
%      % Node data is age (y), height (m), weight (kg)
%      p1 = uitreenode(category1,'Text','Joe','NodeData',[40 1.67 58] );
%      p2 = uitreenode(category1,'Text','Linda','NodeData',[49 1.83 90]);
%      p3 = uitreenode(category2,'Text','Rajeev','NodeData',[25 1.47 53]);
%      p4 = uitreenode(category2,'Text','Anne','NodeData',[88 1.92 100]);
%      
%      % Expand tree to see all nodes
%      expand(tr, 'all');
%
%   Example 2: Check box tree
%      f = uifigure;
%      tr = uitree(f, 'checkbox');
%
%   See also UIFIGURE, UITREENODE

%   Copyright 2017-2021 The MathWorks, Inc.


% If using the 'v0' switch, use the undocumented uitree
if (usev0tree(varargin{:}))
    [treeComponent, container] = matlab.ui.internal.uitree_deprecated(varargin{2:end});
    varargout = {container};
    
else
    
    args.styleNames = { ...
        'tree',...
        'checkbox',...
        };

    args.classNames = {...
        'matlab.ui.container.Tree', ...
        'matlab.ui.container.CheckBoxTree' ...
        };

    args.defaultClassName = 'matlab.ui.container.Tree';
    
    args.functionName = 'uitree';
    
    args.userInputs = varargin;
    
    try
        treeComponent = matlab.ui.control.internal.model.ComponentCreation.createComponentInFamily(args);
    catch ex
        error('MATLAB:ui:Tree:unknownInput', ...
            ex.message);
    end
end
end

function result = usev0tree(varargin)

if (isempty(varargin))
    result = false;
else
    if ((ischar(varargin{1}) || isstring(varargin{1})) && (strcmpi(varargin{1}, 'v0')))
        result = true;
    else
        result = false;
    end
end
end