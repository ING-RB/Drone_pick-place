classdef GatherableMixin
    %GATHERABLEMIXIN Mixin class for objects that need to implement GATHER

    %   Copyright 2024 The MathWorks, Inc.

    methods (Hidden)
        function varargout = gather(varargin)
            %GATHER Gather an object.
            %   GOBJ = GATHER(OBJ) gathers all properties of the input
            %   object OBJ and returns the gathered object as GOBJ. All
            %   properties of the output GOBJ are stored in the local
            %   workspace.
            %
            %   [GOBJ1,GOBJ2,...,GOBJn] =  GATHER(OBJ1,OBJ2,...,OBJn)
            %   gathers multiple objects OBJ1,OBJ2,...,OBJn into the
            %   corresponding outputs GOBJ1,GOBJ2,...,GOBJn.
            %
            %   If all the properties of an input are stored in the local
            %   workspace, then the corresponding output is the same as the
            %   input.
            %
            %   Use this method to create an object whose properties are
            %   all stored in the local workspace from an object that has
            %   properties stored as gpuArrays.
            %
            %   See also gather, gpuArray/gather.
            if nargout > nargin
                error(message("MATLAB:nargoutchk:tooManyOutputs"));
            end

            if nargin==1
                % Short-cut for single input
                varargout = {varargin{1}.gatherOne(class(varargin{1}))};
                return
            end

            persistent thisClassName;
            if isempty(thisClassName)
                thisClassName = mfilename('class');
            end
            varargout = varargin;

            % Gather the GatherableMixins
            isGatherableMixin = false(size(varargin));
            for ii = 1:numel(varargin)
                if isa(varargin{ii}, thisClassName)
                    isGatherableMixin(ii) = true;
                    varargout{ii} = varargin{ii}.gatherOne(class(varargin{ii}));
                end
            end

            % Gather all other arguments
            if any(~isGatherableMixin)
                [varargout{~isGatherableMixin}] = gather(varargin{~isGatherableMixin});
            end
        end
    end

    methods (Abstract, Static, Access = protected)
        % gatherProps is static to allow it to be called dynamically by
        % gatherOne().
        %
        % The method must be re-implemented in every class in a class
        % hierarchy that meets one of the following criterea:
        % - Defines a private access, non-constant, non-immutable,
        %   non-dependent property.
        % - Defines a non-constant, non-immutable, non-dependent property
        %   in an otherwise non-abstract class.
        % - Inherits from 2 or more superclasses which each are subclasses
        %   of GatherableMixin and provide a gatherProps implementation.
        %
        % The implementation must be as follows:
        %
        % function this = gatherProps(this, propsToGather)
        %     % Gathers a single instance of this object. Used by GATHER
        %     props = cell(1,numel(propsToGather));
        %     for ii = 1:numel(propsToGather)
        %         props{ii} = this.(propsToGather{ii});
        %     end
        %     [props{:}] = matlab.internal.parallel.recursiveGatherMulti(props{:});
        %     for ii = 1:numel(propsToGather)
        %         this.(propsToGather{ii}) = props{ii};
        %     end
        % end
        obj = gatherProps(obj, propsToGather)
    end

    methods (Access = private)
        function this = gatherOne(this, className)
            persistent cache
            if isempty(cache)
                cache = configureDictionary("string","cell");
            end
            cachedValues = lookup(cache, className, "FallbackValue",{{}});
            if ~isempty(cachedValues{1})
                propsToGather = cachedValues{1}{1};
                gatherPropsFcn= cachedValues{1}{2};
                superclassesToCallGatherOneOn= cachedValues{1}{3};
            else
                clazz = matlab.metadata.Class.fromName(className);

                % Work out which superclasses we need to call gatherOne on
                needToCallSuperClassGatherOne = false(size(clazz.SuperclassList));
                for ii = 1:numel(clazz.SuperclassList)
                    needToCallSuperClassGatherOne(ii) = iClassHasInaccessiblePropertyThatNeedsGather(clazz, clazz.SuperclassList(ii));
                end
                superclassesToCallGatherOneOn = clazz.SuperclassList(needToCallSuperClassGatherOne);

                % Work out which properties we should gather in this call
                % to gatherOne
                propsToGather = iGetPropertiesThatNeedGather(clazz.PropertyList);
                for ii = 1:numel(superclassesToCallGatherOneOn)
                    % If the property also exists in a superclass we're
                    % calling gatherOne with, we don't want to gather it
                    % from this call to gatherOne as well.
                    propsToGather = setdiff(propsToGather, superclassesToCallGatherOneOn(ii).PropertyList);
                end

                propsToGather = {propsToGather.Name};
                if ~isempty(propsToGather)
                    assert(iHasGatherPropsImpl(clazz), "gatherProps method must be implemented on " + className);
                end
                gatherPropsFcn = str2func(className + ".gatherProps");

                superclassesToCallGatherOneOn = {superclassesToCallGatherOneOn.Name};
                cache = cache.insert(className, {{propsToGather, gatherPropsFcn, superclassesToCallGatherOneOn}});
            end

            % Gather the superclasses
            for ii = 1:numel(superclassesToCallGatherOneOn)
                this = this.gatherOne(superclassesToCallGatherOneOn{ii});
            end

            % Gather the properties we need to in this call
            if ~isempty(propsToGather)
                this = gatherPropsFcn(this,propsToGather);
            end
        end
    end
end

function props = iGetPropertiesThatNeedGather(props)
isConstant = [props.Constant];
isDependent = [props.Dependent];
isImmutable = false(size(isConstant));
for ii = 1:numel(props)
    isImmutable(ii) = iIsImmutable(props(ii).SetAccess);
end
props = props(~isConstant & ~isDependent & ~isImmutable);
end

function tf = iClassHasInaccessiblePropertyThatNeedsGather(accessingClass, clazz)
for ii = 1:numel(clazz.SuperclassList)
    if iClassHasInaccessiblePropertyThatNeedsGather(accessingClass, clazz.SuperclassList(ii))
        tf = true;
        return
    end
end
props = iGetPropertiesThatNeedGather(clazz.PropertyList);
for ii = 1:numel(props)
    if (~iCanAccess(accessingClass, props(ii).SetAccess)) || (~iCanAccess(accessingClass, props(ii).GetAccess))
        tf = true;
        return
    end
end
tf = false;
end

function tf = iHasGatherPropsImpl(clazz)
tf = false;
isGatherProps = {clazz.MethodList.Name} == "gatherProps";
if ~any(isGatherProps)
    return
end
gatherPropsMethod = clazz.MethodList(isGatherProps);

if gatherPropsMethod.Abstract || ~gatherPropsMethod.Static
    return
end
tf = true;
end

function tf = iIsImmutable(access)
tf = ischar(access) && access == "immutable";
end

function tf = iCanAccess(accessingClass, access)
if ischar(access)
    tf = access == "protected" || access == "public";
elseif isa(access, "matlab.metadata.Class")
    tf = accessingClass == access;
else
    assert(iscell(access), "Expected access to be a cell array");
    % access is a cell array of matlab.metadata.Class. [access{:}] converts
    % this to an array of matlab.metadata.Class that we can use == with.
    tf = any([access{:}] == accessingClass);
end
end
