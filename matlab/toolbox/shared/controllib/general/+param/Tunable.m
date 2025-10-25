classdef Tunable < param.Parameter
    %Construct a tunable parameter
    %
    %    Tunable parameters are parameters that can be tuned.  They have a
    %    field with a value, and a field indicating whether that value is
    %    free to be tuned, e.g. for optimization.

    % Copyright 2022 The MathWorks, Inc.

    properties (Abstract)
        Value
        Free
    end

    properties(Hidden = true, GetAccess = public, SetAccess = public)
        %TAG
        %
        Tag = '';
    end % hidden public properties

    methods(Hidden = true, Sealed = true)
        function pv = getPVec(this, varargin)
            % GETPVEC Gets the variable values.
            %
            %   PV = GETPVEC(OBJ) returns the vector of current variable values.
            %   All variables are included, both free and fixed.
            %
            %   PV = GETPVEC(OBJ,'free') returns the vector of free variable values.
            %
            %   See also SETPVEC.
            [pv,pf] = vec(this);
            if nargin > 1
                % Using the 'free' flag.
                pv = pv(pf);
            end
        end

        function this = setPVec(this, pv, varargin)
            % SETPVEC Sets the variable values.
            %
            %   OBJ = SETPVEC(OBJ,PV) sets the variable values to the values
            %   specified in the vector PV.  The length of PV should be
            %   equal to the total number of elements in OBJ.
            %
            %   OBJ = SETPVEC(OBJ,PV,'free') sets the values of the free
            %   variables only.  The remaining variables are held at their
            %   current value.
            %
            %   See also GETPVEC.
            if ~isvector(pv)
                error(message('Controllib:modelpack:InvalidArgumentForCommand', 'PV', 'setPVec'))
            end

            [p, pf] = vec(this);
            if nargin > 2
                % Using the 'free' flag.
                try
                    p(pf) = pv(:);
                catch
                    error(message('Controllib:modelpack:InvalidArgumentForCommand', 'PV', 'setPVec'))
                end
            else
                if length(pv) ~= length(p)
                    error(message('Controllib:modelpack:InvalidArgumentForCommand', 'PV', 'setPVec'))
                end
                p = pv;
            end

            % Assign values
            ip = 0;
            for ct = 1:numel(this)
                spj = this(ct).Size_;
                npj = prod(spj);
                this(ct) = setPVecElement(this(ct), p(ip+1:ip+npj));
                ip = ip + npj;
            end
        end

        function pS = sInfo(this)
            % Get structural information about parameter. Returns a logical array pS of
            % the same size as the parameter where FALSE indicates entries fixed to zero
            % and TRUE indicates entries that can vary or are fixed to a nonzero value.
            pS = (this.Free | this.Value~=0);
        end

        function index = findDiscreteParameters(this)
            %FINDDISCRETEPARAMETERS Find indices of discrete parameters
            tf = false(size(this));
            for ct = 1:numel(tf)
                tf(ct) = isa(this(ct), 'param.Discrete');
            end
            index = find(tf);
        end
    end % hidden public sealed methods


    %Methods that must be in inheriting classes
    methods (Hidden, Abstract)
        [x,mn,mx,typ,sca] = parToVecForOptim(this)
        p                 = vecToParForOptim(this,x)
    end

    methods (Abstract, Access = protected)
        [value,free] = vecElement(this)
        p            = setPVecElement(this,pv)
    end

    methods (Hidden)
        function tf = isDiscrete(this) %#ok<MANU> 
            %ISDISCRETE Return whether object is discrete
            %    The parameter object must be scalar
            %
            arguments
                this (1,1)
            end

            %Set here; subclasses can override
            tf = false;
        end
    end

    methods(Hidden = true, Sealed = true, Access = protected)
        function [value, free] = vec(this)
            %VEC Vectorize variable data

            %Determine number of entries in outputs
            numValues = zeros(numel(this), 1);
            for ct = 1:numel(this)
                numValues(ct) = numel(this(ct).Value);
            end

            %Preallocate outputs
            totalValues = sum(numValues);
            value = zeros(totalValues,1);
            free  = true(totalValues,1);
            %Populate outputs
            i2 = 0;
            for ct = 1:numel(this)
                param = this(ct);
                if numValues(ct) > 0
                    i1 = i2 + 1;
                    i2 = i1 + numValues(ct) - 1;
                    [v,f] = vecElement(param);
                    value(i1:i2) = v;
                    free(i1:i2)  = f;
                end
            end
        end
    end % hidden sealed protected methods
end