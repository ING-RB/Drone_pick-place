%  m3i.Validator is the base class for writing constraints checks.
%  Clients can inherit for m3i.Validator and define validation methods with
%  a predefined naming convention:
%  E.g:
%
%       classdef MyConstraintChecker < m3i.Validator
%           methods (Access=public)
%
%               % Connector must have valid ends.
%               function UMLConnector_constraint_validEnds(self, connector);
%
%               % A Property must have a valid type.
%               function UMLProperty_constraint_validType(self, attribute);
%                
%               % A property must belong to a classifier.
%               function UMLProperty_constraint_validClassifier(self, attribute);
%
%                % Post process constraints on connectors.
%                function UMLConnector_post_process(self);
%
%           end
%       end
%
%  As seen above, the name of a constraint function starts with the type to
%  which it is applied. The type is specified using the same scheme as when
%  writing visitors in MATLAB - ie. fully qualified name devoid of .
%  characters. E.g: UML.Connector is specified as UMLConnector.
%
%  The constraints must have public visibility. This is because private
%  methods cannot be accessed through MATLAB's introspective API (methods).
%
%  As seen above, multiple constraints can be defined for the same type.
%  
%  Constraint functions must use the error, warning, info functions
%  available in m3i.Validator to emit messages.
%
%  When a fundamental constraint is violated, fundamentalError must be used
%  to raise an exception and to abort validation. Fundamental errors are
%  issues with SCP infrastructure that must be fixed. Fundamental errors
%  often don't make sense to the end-user. They reflect issues with SCP
%  infrastructure.
%
%  To initiate validation, the verify method is used.
%  E.g:  
% 
%      v = MyValidator();
%      v.verify(someM3IObject);
%
%  Reusing the same validator after verify has been called on it is
%  discouraged.
% 
%  isExactly helper function can be used to check if a given object is an
%  instance of a given type.
%
%  Clients can also define methods post_process methods that can be used to
%  perform additional constraints after the entire composition hierarchy
%  has been traversed.
%
% No guarantee is provided as to the order in which multiple constraints on
% a given type will be executed.
%

%   Copyright 2010-2022 The MathWorks, Inc.

classdef Validator < handle
    methods (Access=public)
        % Constructor
        function self = Validator(varargin)
            % Use a C++ based dispatch table (M3I.GenericVisitor) to group
            % and dispatch constraint checks.
            self.dispatcher = M3I.GenericVisitor();
            if nargin > 0 
                self.prefix = varargin{1};
            else
                self.prefix = '';
            end
            self.scheduleConstraintChecks();
            
            % Initialize message counts to zero.
            self.errorCount = 0;
            self.warningCount = 0;
            self.infoCount = 0;
        end
        
        %destructor
        function delete(~)
        end
        
        % Validate a given object.
        function [errorCount, warningCount] = verify(self, object)

            % Validate the object and its children.
            self.verifyObjectRecursive(object);
            
            % if the object's m3iModel references another m3iModel, verify
            % that m3iModel too
            if isa(object.rootModel, 'Simulink.metamodel.foundation.Domain')
                if Simulink.AutosarDictionary.ModelRegistry.hasReferencedModels(object.rootModel)
                    refM3IModel = autosar.dictionary.Utils.getUniqueReferencedModel(object.rootModel);
                    objInRefModel = Simulink.metamodel.arplatform.ModelFinder.findPeerObjectInOtherModel(...
                        object, refM3IModel);
                    if objInRefModel.isvalid()
                        self.verifyObjectRecursive(objInRefModel);
                    end
                end
            end
            self.invokePostProcessConstraints();
            
            % Relinquish the dispatcher object. 
            % This should get rid of references to 'self' from C++.
            self.dispatcher = [];
            
            % Return the message counts. 
            % This is useful for writing code like
            % nErrors = validator.verify(model);
            % if nErrors ...            
            errorCount = self.errorCount;
            warningCount = self.warningCount;
        end
        
        % Raise an exception when fundamental integrity has been violated.
        function fundamentalError(~, msg)
            % Fundamental error will be caught by the outermost function of
            % the validator. Fundamental Error will be thrown as part of
            % finding the correct software or algo end of a connector (this
            % needs to be changed) and therefore we do not want to
            % increment the error count.
            % self.errorCount = self.errorCount + 1;
            throw (MException('', msg));
        end
        
        % Emit an error message.
        % Also increment the error count
        function error(self, msgId, varargin)
            self.errorCount = self.errorCount + 1;
            if ~self.silentMode
                m3iError(msgId, varargin{:});
            end
        end
        
        % Emit a warning message.
        % Also increment the warning count.
        function warning(self, msgId, varargin)
            self.warningCount = self.warningCount + 1;
            if ~self.silentMode
                m3iWarning(msgId, varargin{:});
            end
        end       
        
        % Emit an info message.
        % Also increment the info count.
        function info(self, msgId, varargin)
            self.infoCount = self.infoCount + 1;
            if ~self.silentMode
                m3iWarning(msgId, varargin{:});
            end
        end 
        
        % Is an object of a given type?
        function res = isExactly(~, obj, className)
            res = obj.isvalid && strcmp(class(obj), className);
        end        
    end
    
    methods (Access=private)
        % Find out the set of constraints being defined.
        % This relies on MATLAB introspection. So the constraints being
        % defined in the sub-class of Validator (ie concrete type of self)
        % must be 'public'.
        function constraintChecks = gatherConstraints(self)
            
            % Constraint functions are of the form
            %      type _constraint_ name
            % E.g: GenericComponentFlowPort_constraint_isTyped
            %
            expr = '([^_]+)_constraint_.+';
            
            methodsOfClass = methods(self);
            constraintChecks = containers.Map;
            
            % Use introspection to find out all the methods in the concrete
            % validator class. Note: only 'public' methods are processed by
            % this loop.
            for i = 1 : numel(methodsOfClass)
                methodName = methodsOfClass{i};
                
                % Use regexp to find methods that follow the constraint
                % naming convention.
                % The 'tokens' argument to regexp causes the individual
                % tokens in the matched string to be returned.
                % In our regexp, the first token would be the type.
                tokens = regexp(methodName, expr, 'tokens');
                nTokens = length(tokens);
                if nTokens == 1
                    typeTag = tokens{1};
                    typeTag = typeTag{1};
                    
                    % Using the () operator on the map with an argument
                    % that is not yet a valid key throws an exception.
                    % So we need to first check whether a type is a key and 
                    % if not, make it a valid key by inserting and empty
                    % cell.
                    % We use a cell array rather than an array because
                    % array of function handles is not supported by MATLAB.
                    if ~constraintChecks.isKey(typeTag)
                        constraintChecks(typeTag) = {};
                    end
                    
                    % Make a function handle.
                    constraintCheckFunction = eval(['@' methodName]);
                    
                    % constraintChecks(typeTag){end+1} = constraintCheckFunction
                    % The above syntax is not supported by MATLAB. 
                    % So we first get the current set of constraints for
                    % the type from the map.
                    constraintsForType = constraintChecks(typeTag);
                    
                    % Append the new constraint to the set of constraints.
                    constraintsForType{end+1} = constraintCheckFunction; %#ok<AGROW>
                    
                    % Update the map with the updated set of constraints
                    % for the type.
                    constraintChecks(typeTag) = constraintsForType;
                elseif nTokens == 0
                    % ignore this method
                else
                    % todo:  raise a development error
                end
            end
        end
        
        % Given a set of constraints, apply it to  given object.
        % constraints are specified as a cell-array of function handles
        % because MATLAB doesn't support an array of function handles.
        function applyConstraintChecks(self, object, constraints)
            for i=1:length(constraints)
                constraintCheck = constraints{i};
                constraintCheck( self, object );
            end
        end        
        
        % Schedule the constraint checks for invocation.
        function scheduleConstraintChecks(self)
			
            constraintChecks = self.gatherConstraints();            
            keys = constraintChecks.keys();
            
            % For each type with a set of constraints ...
            for i=1:length(keys)
                typeTag = keys{i};
                constraintsForType = constraintChecks(typeTag);
                
                % Create a lambda that given a validator and an object of 
                % the type, applies the set of constraints on that object.
                % The lambda is intentionally not defined as:
                % @(object) self.applyConstraintChecks(object, constraintsForType).
                % Doing go would cause 'self' to be captured in a closure
                % that gets registered with the dispatcher. This would result
                % in a cyclic reference: self->dispatcher->closure->self
                % So to avoid that we require self to be passed explicitly
                % to the lambda - (v below):
                % lambda = @(v, object) v.applyConstraintChecks(object, constraintsForType);
                % self.dispatcher.bind(typeTag, lambda);
                %
                % It turns out that the above scheme does not work either.
                % Defining lambda here also causes the self to be captured
                % irrespective of whether self is used by the lambda or
                % not.
                % So we resort to calling a static method that creates the
                % lambda. Use of the static method means that there is not
                % self parameter and therefore self is not captured in a
                % closure.
                lambda = m3i.Validator.createLambda(constraintsForType);
                try 
                    self.dispatcher.bind(typeTag, lambda);
                catch 
                    self.dispatcher.bind([self.prefix typeTag], lambda);
                end
            end
        end     
                
        % Validate an object by applying constraints and then validate its
        % children.
        function verifyObjectRecursive(self, object)
            if ~object.isvalid
                here = 1;
            end
            % apply constraints on the object
            [constraintChecker, actualObject] = self.dispatcher.fetch(object);
            constraintChecker(self, actualObject);
            
            containees = object.containeeM3I;
            nContainees = containees.size();
            for i=1:nContainees
                child = containees.at(i);
                
                % Due to a bug, unused 1..1 properties appear as null
                % objects in the containeeM3Is list.
                % Ignore such objects.
                if ~child.isvalid
                    % ignore empty object
                    continue;
                end
                
                self.verifyObjectRecursive(child);
            end
        end
        
        
        % Invoke post process constraints if defined.
        function invokePostProcessConstraints(self)
            expr = '([^_]+)_post_process_.+';
            
            methodsOfClass = methods(self);
            constraintChecks = containers.Map;
            
            % Use introspection to find out all the methods in the concrete
            % validator class. Note: only 'public' methods are processed by
            % this loop.
            for i = 1 : numel(methodsOfClass)
                methodName = methodsOfClass{i};
                
                % Use regexp to find methods that follow the post process 
                % constraint naming convention.
                % The 'tokens' argument to regexp causes the individual
                % tokens in the matched string to be returned.
                % In our regexp, the first token would be the type.
                tokens = regexp(methodName, expr, 'tokens');
                nTokens = length(tokens);
                
                if nTokens == 1
                    % TODO: make sure the prefix of post process methods denote
                    % a valid type tag.
                    
                    % Invoke the post process method.
                    self.(methodName)();                
                end
            end       
        end
    end
    
    methods (Access=private, Static)
        % Create a lambda that is registered with the C++ based dispatcher.
        % A static method is used to create the lambda because otherwise
        % the self parameter gets captured as part of the lambda.
        function lambda = createLambda(constraintsForType)
            lambda = @(v, object) v.applyConstraintChecks(object, constraintsForType);
        end
    end
    
    methods (Access=public)
        function M3IObject_constraint_empty(self, obj) %#ok<MANU,INUSD>
            % By default no constraints are applied to an object
        end
    end
    
    properties (Access=public)
        prefix;
        dispatcher;
        errorCount;
        warningCount;
        infoCount;
        silentMode = false;
    end
end
% LocalWords:  UML ie IObject validator algo containee uri metamodel
