classdef meshmaterial < matlab.mixin.indexing.RedefinesDot & matlab.mixin.CustomDisplay % & matlab.mixin.Scalar

    properties (Access=public)
        Name = "";
    end
    properties (Access=public)
        Custom struct = struct;
    end

    methods(Hidden)
        function out = properties(obj)
            if length(obj) > 1
                out = {'Name'};
            else
                out = fieldnames(obj.Custom);
                out = ["Name"; out];
            end
        end
    end
    methods (Access=public)
        function obj = meshmaterial(name, props)
            arguments
                name (1,1) string {mustBeNonempty, mustBeNonsparse} = ""
                props(1,1) struct = struct
            end
            if nargin == 1
                obj.Name = name;
                obj.Custom = struct;
            elseif nargin == 2
                obj.Name = name;
                obj.Custom = props;
            end
            
        end
        
        function newObj = removeAttribute(obj, propname)
            newObj = obj;
            newObj.Custom = rmfield(newObj.Custom, propname);
        end
    end

    methods (Access=protected)
        function varargout = dotReference(obj,indexOp)
            [varargout{1:nargout}] = obj.Custom.(indexOp);
        end

        function obj = dotAssign(obj,indexOp,varargin)
            validateDynamicProp(varargin);
            [obj.Custom.(indexOp)] = varargin{:};
        end
        
        function n = dotListLength(obj,indexOp,indexContext)
            n = listLength(obj.Custom,indexOp,indexContext);
        end

       function propgrp = getPropertyGroups(obj)
           if ~isscalar(obj)
              propgrp = matlab.mixin.util.PropertyGroup("Name", "");%getPropertyGroups@matlab.mixin.CustomDisplay(obj);
           else
               n.Name = obj.Name;
               propgrp(1) = matlab.mixin.util.PropertyGroup(n, "Required : ");
               propgrp(2) = matlab.mixin.util.PropertyGroup(obj.Custom, "Custom : ");
           end
       end
    end
end

function validateDynamicProp(value)
    % Validate non-size attributes
    validateattributes(value{:}, {'vector', 'double', 'string', 'logical'}, {'nonsparse' 'nonempty' 'real'});
    
    isMx1 = isvector(value{:});
    if ~(isMx1) && isempty(value{:})
        error("Property value should be a string, bool, scalar or a vector");
    end
end

% classdef MeshMaterial < dynamicprops
%     %MATERIALPROPERTIES Summary of this class goes here
%     %   Detailed explanation goes here
% 
%     properties(Access = public)
%         Name(1,1) string
%     end
% 
%     methods
%         function obj = MeshMaterial(name)
%             arguments
%                 name (1,1) string {mustBeNonempty, mustBeNonsparse}
%             end
% 
%             % Construct object
%             obj.Name = name;
%         end
% 
%         % Add property
%         function obj = addMaterialProperty(obj, name, val)
%             arguments
%                 obj
%                 name (1,1) string {mustBeNonempty}
%                 val = []
%             end
% 
%             addprop(obj, name, val);
%         end
% 
% 
%         % Delete property
%         function obj = deleteMaterialProperty(obj, name)
%             arguments
%                 obj
%                 name (1,1) string {mustBeNonempty}
%             end
% 
%             deleteprop(obj, name);
%         end
% 
%         function set.Name(this,name)
%             this.Name = name;
%         end
%     end
% 
%     methods(Hidden)
%         % Add property
%         function prop = addprop(obj, name, val)
%             arguments
%                 obj
%                 name (1,1) string {mustBeNonempty}
%                 val = []
%             end
%             validateDynamicProp(val)
%             % Add
%             prop = addprop@dynamicprops(obj, name);
%             prop.SetMethod = propertySetFunction(obj, name);
% 
%             % Set to new value
%             obj.(name) = val;
%         end
% 
%         % Delete property
%         function prop = deleteprop(obj, name)
%             % Ensure exists
%             prop = findprop(obj, name);
%             if isempty(prop)
%                 error("Doesn't exist!")
%             end
% 
%             % Ensure dynamic prop
%             if ~isa(prop, "meta.DynamicProperty")
%                 error("Cannot remove non-dynamic property!")
%             end
% 
%             % Delete property
%             delete(prop);
%         end
%     end
% 
%     methods(Access=protected)
%         % Custom display of properties
%         % function group = getPropertyGroups(obj)
%         %     % Group properties as native/required vs. added
%         %     fieldNames = string(builtin("fieldnames", obj));
%         %     numFields = numel(fieldNames);
%         %     % for fieldIdx = 1:numel(numFields)
%         %     %     nativeIdx(strcmp(obj.RequiredDynamicProperties(fieldIdx), fieldNames)) = true;
%         %     % end
%         %     % for fieldIdx = 1:numFields
%         %     %     if ~nativeIdx(fieldIdx)
%         %     %         nativeIdx(fieldIdx) = ~isa(findprop(obj, fieldNames(fieldIdx)), 'meta.DynamicProperty');
%         %     %     end
%         %     % end
%         %     required = fieldNames(1);
%         %     added = sort(fieldNames(2:numFields));
%         %     group(1) = matlab.mixin.util.PropertyGroup(required, "");
%         %     %group(2) = matlab.mixin.util.PropertyGroup(added, "Custom Properties");
%         % end
% 
%         % Dynamic property set function
%         function f = propertySetFunction(obj, name) %#ok<INUSD>
%             function setProp(obj, val)
%                 validateDynamicProp(val)
%                 obj.(name) = val;
%             end
%             f = @setProp;
%         end
%     end
% end
% 
% function validateDynamicProp(value)
%     % Validate non-size attributes
%     validateattributes(value, {'single', 'double', 'string', 'logical'}, {'nonsparse' 'nonempty' 'real'});
% 
%     isMx1 = isvector(value);
%     if ~(isMx1) && ~isempty(value)
%         error("Property value should be a string, bool, scalar or a vector");
%     end
% end