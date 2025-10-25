classdef Explorable < matlab.mixin.SetGet & matlab.mixin.internal.TreeNode & matlab.mixin.Heterogeneous
%DAStudio.Explorable class

%    DAStudio.Explorable properties:
%       Path - Property is of type 'ustring'  (read only) 
%       Children - Property is of type 'handle vector'  
%
%    DAStudio.Explorable methods:
%       setChildren -  the sole purpose of this setter function is to create necessary listeners
%
%    Delete this when Model Advisor is no longer on ME infrastructure


properties (SetObservable=true)
    %CHILDREN Property is of type 'handle vector' 
    Children
end

properties (SetObservable, Hidden)
    %LISTENERS Property is of type 'handle vector' (hidden)
    Listeners 
end


    methods  % constructor block
        function this = Explorable
        end     
    end

    methods % set and get functions 
        function set.Children(h, value)
            h.Children = setChildren(h, value);
        end

    end

    methods  % public methods
        %----------------------------------------
        
       function children = setChildren(h, children)
       % the sole purpose of this setter function is to create necessary listeners
       % on the incoming objects so that the DAStudio.Explorable object can remain
       % in sync with its childrens' lifespan
       
           childListeners  = {};
           parentListeners = {};
           parents         = {};
           
           if isempty(children)
               % remove previous listeners
               h.Listeners = [];
           else
               % we will listen to events triggered from the parent so add listeners
               % only to those child objects that do not have a parent
               for i = 1:length(children)
                   if isempty(children(i).getParent) && ~isscalar(children)
                       if ishandle(children(i))
                           % Still need to support UDD DAStudio.Shortcut,
                           % which is created thru daexplore.
                           % Delete after DAStudio.Shortcut is converted.
                           childListeners{end+1} = handle.listener(children(i),...
                                                                   'ObjectBeingDestroyed',...
                                                                   {@childDestroyedHandler, h});
                       else % MCOS
                           childListeners{end+1} = event.listener(children(i),...
                                                                  'ObjectBeingDestroyed',...
                                                                  @(h, e) childDestroyedHandler(h, e, h));
                       end
                   else
                       parents{end+1} = children(i).getParent;
                   end
               end
               
               parents = unique([parents{:}]);
               for i = 1:length(parents)
                   if ishandle(parents(i)) || any(ishandle(parents(i).Children))
                       % Still need to support UDD DAStudio.Shortcut,
                       % which is created thru daexplore
                       % Delete after DAStudio.Shortcut is converted.
                       parentListeners{end+1} = handle.listener(parents(i),...
                                                                'ObjectBeingDestroyed',...
                                                                {@parentDestroyedHandler, h});
                       parentListeners{end+1} = handle.listener(parents(i),...
                                                                'ObjectChildRemoved',...
                                                                {@childRemovedHandler, h});
                   else % MCOS
                       parentListeners{end+1} = event.listener(parents(i),...
                                                               'ObjectBeingDestroyed',...
                                                               @(h, e) parentDestroyedHandler(h, e, h));
                       parentListeners{end+1} = event.listener(parents(i),...
                                                               'ObjectChildRemoved',...
                                                               @(h, e) childRemovedHandler(h, e, h));
                   end
               end
               
               h.Listeners = [childListeners{:} parentListeners{:}];
           end
       end  % setChildren
       
       %% Event handlers ---------------------------------------------------------

end  % public methods 

    methods
        %----------------------------------------
       function children = getChildren(h)
           children = h.Children;
       end
       
        %----------------------------------------
       function dlgStruct = getDialogSchema(~, ~)
           empty.Type                  = 'text';
           empty.Name                  = '';
           
           dlgStruct.DialogTitle       = 'List Explorer';
           dlgStruct.Items             = {empty};
           dlgStruct.EmbeddedButtonSet = {''};
       end
       
        %----------------------------------------
       function children = getHierarchicalChildren(h)
           % children = [];
           children = h.Children;
       end
       
        %----------------------------------------
       function b = isHierarchical(~)
           b = true;
       end
       
    end

end  % classdef

function childDestroyedHandler(h, e, root, varargin)
    c = root.Children;
    for i = 1:length(c)
        if c(i) == h
            c(i) = [];
            break;
        end
    end
    if (ishandle(c))
        root.Children = c(ishandle(c));
    else
        if ~isempty(c)
            root.Children = c(isobject(c));
        else
            root.Children = [];
        end
    end
end  % childDestroyedHandler


function childRemovedHandler(h, e, root, varargin)
    c = root.Children;
    for i = 1:length(c)
        if c(i) == e.Child
            c(i) = [];
            break;
        end
    end
    if isa(c, 'DAStudio.Shortcut')
        root.Children = c(ishandle(c));
    else
        if ~isempty(c)
            root.Children = c(isobject(c));
        else
            root.Children = [];
        end
    end
end  % childRemovedHandler


function parentDestroyedHandler(h, e, root, varargin)
    c = root.Children;
    if isa(c, 'DAStudio.Shortcut')
        root.Children = c(ishandle(c));
    else
        if ~isempty(c)
            root.Children = c(isobject(c));
        else
            root.Children = [];
        end
    end
end  % parentDestroyedHandler

