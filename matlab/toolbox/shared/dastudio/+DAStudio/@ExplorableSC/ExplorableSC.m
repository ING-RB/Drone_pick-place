classdef ExplorableSC < imported.DAStudio.Shortcut
%DAStudio.ExplorableSC class

%   DAStudio.ExplorableSC extends DAStudio.Shortcut.
%

%    DAStudio.ExplorableSC properties:
%       Path - Property is of type 'ustring'  (read only) 
%
%    DAStudio.ExplorableSC methods:

%#exclude imported.DAStudio.Shortcut
%#function DAStudio.Shortcut

    properties (SetObservable, Hidden)
        %RECURSIVE Property is of type 'bool'  (hidden)
        Recursive logical = 1;
        %CHILDREN Property is of type 'handle vector'  (hidden)
        Children 
        %LISTENERS Property is of type 'handle vector'  (hidden)
        Listeners 
    end

    methods  % constructor block
        function this = ExplorableSC(target)
            %% error checking         
            % supply default argument if necessary.
            % MATLAB catches case of too many arguments.
            
            if nargin == 0
                target = DAStudio.Object;
            end
            
            if ~isa(target, 'DAStudio.Object')
                error('DAStudio:ExplorableSC:DAStudioObjectRequired', 'Input argument must be a subclass of DAStudio.Object');
            end
            
            %% creation
            this@imported.DAStudio.Shortcut(target);
        
        end        
    end  % constructor block

    methods 
    end   % set and get functions 

    methods (Hidden) % possibly private or hidden
        %----------------------------------------
       function children = getChildren(this)
           children = recursiveGetChildren(this, this.Recursive);
           children = filter(children);
       end
       
       %% recursively calculate the connected children in the UDD tree
        %----------------------------------------
       function masked = isMasked(~)
           masked = false;      
       end     
    end  % possibly private or hidden 
end  % classdef

function children = recursiveGetChildren(obj, recursive)

    children = [];
    
    if isempty(obj)
        return;
    end
    
    current  = obj.down;
    
    while ~isempty(current)
        children = [children current];
    
        if recursive
            children = [children recursiveGetChildren(current, recursive)];
        end
            
        current  = current.right;
    end
end  % recursiveGetChildren


%% filter the objects to only those held by the root ExplorableSC
function filteredChildren = filter( rawChildrenSC )

    filteredChildren = [];
    
    if isempty(rawChildrenSC)
        return;
    end
    
    root = getRoot( rawChildrenSC(1) );
    
    if ~isempty(root.Children)
        for i = 1:length(rawChildrenSC)
            rawChildren(i) = rawChildrenSC(i).getForwardedObject;
        end
        
        filteredChildren = intersect(root.Children, rawChildren);
    end
end  % filter


%% helpers
function root = getRoot( obj )
    if isempty( obj.getParent )
        root = obj;
    else
        root = getRoot( obj.getParent );
    end
end  % getRoot

