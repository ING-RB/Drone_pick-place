classdef INSModelShared < handle
%   This class is for internal use only. It may be removed in the future.
%INSModelShared Base class of positioning.INSModelShared    

%   Copyright 2021-2022 The MathWorks, Inc.      
  
%#codegen

    methods
    
        function dfdx = stateTransitionJacobian(obj, filt, dt, varargin)
        %STATETRANSITIONJACOBIAN numeric Jacobian of stateTransition
            
            % We cannot put varargin into the closure of fun(). MATLAB Coder
            % will error.  Instead assign varargin to vargs and capture that in
            % the closure.
            vargs = varargin;
            % function handle with state as input.
            function z = fun(s)
                filt.State = s;
                sdot = stateTransition(obj, filt, dt, vargs{:});
                % s is a struct. It needs to be an array for
                % numericJacobian to work so flatten it.
                z = struct2vec(sdot);
            end
            dfdxArr = obj.computeWithNumericJacobian(filt, @fun);
            
            %%%%%%%%%%%%
            % Pack dfdxArr into a struct;
            % 1. first get a prototype
            ztmp = stateTransition(obj, filt, dt, varargin{:});
            % 2. Walk over the prototype and create a new struct znew and
            % populate with consecutive row elements of the array.

            fn = fieldnames(ztmp);
            if ~isempty(fn)
                rowCnt = 1;
                for ii=1:numel(fn)
                    fld = fn{ii};
                    nr = numel(ztmp.(fld));
                    nc = numel(filt.State);
                    znew.(fld) = zeros(nr, nc, 'like', filt.State);
                    % Copy rows one by one
                    for rr=1:nr
                        znew.(fld)(rr,:) = dfdxArr(rowCnt,:);
                        rowCnt = rowCnt + 1;
                    end
                end
                dfdx = znew;
            else
                % If there are no fields. Just return ztmp which is a
                % struct with no fields.
                dfdx = ztmp; 
            end
        end

        function c = copy(obj)
            % Default copy. Warns (in sim) if there are non public properties.
            cls = class(obj);
            constructor = str2func(cls);
            c = constructor();

            % Get list of settable properties
            exempt = coder.const(obj.getInternalProps);

            coder.extrinsic('positioning.internal.settableProps');
            [s, haspriv] = coder.const(@positioning.internal.settableProps, cls, exempt);

            % If there are private/protected properties, throw a warning
            % but just keep going. Two paths for warning: sim and codegen
            if haspriv
                if coder.target('MATLAB')
                    warning(message('insframework:insEKF:CopyPrivateProtected', cls));
                else
                    coder.internal.compileWarning('insframework:insEKF:CopyPrivateProtected', cls);
                end
            end
        
            % Set the properties on the copied object with the current
            % values.
            coder.unroll;
            for ii=1:numel(s)
                thisProp = s{ii};
                c.(thisProp) = obj.(thisProp);
            end

        end

    end

    methods (Access = protected)
        function p = getInternalProps(~)
            % Default implementation is no internal props
            p = {};
        end
    end

    methods (Static, Hidden)
        % Static for testability (rather than a class function)
        function y = computeWithNumericJacobian(filt, fun)
            % Computes the numeric jacobian of fun which takes a single
            % input of a state vector.
            % filt is the insEKF
            % fun is a function handle fun(s) where s is filt.State.
            
            % Setup:
            cache = cacheFilter(filt);
            stateCache = filt.State;
            y = matlabshared.tracking.internal.numericJacobianAdditive(fun, stateCache, {}, 1);
            % Teardown:
            restoreFromCache(filt, cache);
        end
        
    end

    
end
   
function vec = struct2vec(s)
% STRUCT2VEC Convert a struct to a column vector
% The input s is a struct. The output vec is a column vector
fn = fieldnames(s);
if isempty(fn)
    vec = [];
    return;
end
% Figure out array size
Neach = structfun(@numel, s);
N = sum(Neach);

exemplar = s.(fn{1}); % extract 1st field for datatype
vec = zeros(N,1, 'like', exemplar);

idx = 1;
for ii=1:numel(fn)
    fld = fn{ii};
    vec(idx:idx+Neach(ii)-1) = s.(fld);
    idx = idx + Neach(ii);
end

end

function cache = cacheFilter(filt)
% Theoretically only state needs caching unless the user is doing something
% unexpected.
cache = struct('State', filt.State);
end
function restoreFromCache(filt, cache)
% Restore the filter State and StateCovariance
filt.State = cache.State;
end
