classdef (Hidden) rotationalInterpolant
%   This class is for internal use only. It may be removed in the future. 
%ROTATIONALINTERPOLANT  Internal rotational interpolant class 
%	A collection of validation methods for interp1 and an interface to the 
%	strategy class for the specific type of interpolation.

    %   Copyright 2024 The MathWorks, Inc.
    
    %#codegen

    properties
        XLUT	% Table indices
        VLUT	% Table values
        ExtrapVal % Extrapolation value
    end

    properties 
        Interpolator	% Interpolation strategy class
    end

    methods
        function obj = setLut(obj, xlut, vlut)
              %SETLUT set the table indices and values

            obj.XLUT = xlut;
            obj.VLUT = vlut;
        end
        function obj = setInterpolator(obj, methodname)
          % SETINTERPOLATOR Set the interpolation strategy
            
            coder.internal.prefer_const(methodname);
            switch methodname 
                case 'slerp-short'
                    obj.Interpolator = ...
                        matlabshared.rotations.internal.interpolation.SlerpShortStrategy;
                case 'slerp-natural'
                    obj.Interpolator = ...
                        matlabshared.rotations.internal.interpolation.SlerpNaturalStrategy;
                case 'nearest'
                    obj.Interpolator = ...
                        matlabshared.rotations.internal.interpolation.NearestStrategy;
                case 'previous'
                    obj.Interpolator = ...
                        matlabshared.rotations.internal.interpolation.PreviousStrategy;
                case 'next'
                    obj.Interpolator = ...
                        matlabshared.rotations.internal.interpolation.NextStrategy;
                case 'squad-natural'
                    obj.Interpolator =  ...
                        matlabshared.rotations.internal.interpolation.SquadNaturalStrategy;
            end
        end
        function obj = setExtrapVal(obj, ev)
            obj.ExtrapVal = ev;
        end

        function yq = interpolate(obj, xq)
		  % Interpolate the data. Unroll data appropriately and hand off vector-to-vector interpolation
		  % to the interpolateVector method
            ev = obj.ExtrapVal;
            xlut = obj.XLUT(:); % unroll

            vlut = normalizeLut(obj.Interpolator, obj.VLUT);

      	    vsize = size(vlut);
      		viter = prod(vsize(2:end));
            if ~isvector(vlut)
                vlut = reshape(vlut, vsize(1), viter); % a matrix
            else
                vlut = vlut(:);
                viter = 1;
            end
            if ~issorted(xlut)
                [xlut, idx] = sort(xlut);
                vlut = vlut(idx,:);
            end

            % Check for repeated values in xlut. This is faster than a
            % loop.
            coder.internal.assert(all(diff(xlut) ~= 0), 'shared_rotations:interpolation:UniqueSamplePoints' );
           
            % Interpolator is a value class
            obj.Interpolator = plan(obj.Interpolator, xlut, vlut);

            % Allocate output. Reshape it later.
            t = computeOutputType(xlut,vlut,xq);
            yq = quaternion.zeros([numel(xq) viter],t); 

            for ii=1:viter
                thisv = vlut(:,ii);
                yq(:,ii) = obj.interpolateVector(xlut, thisv, xq(:), ev, ii);
            end

            if isvector(obj.VLUT)
                yq = reshape(yq, size(xq));
            else
                if isvector(xq)
                   yq = reshape(yq, [numel(xq), vsize(2:end)]);
                else
                   yq = reshape(yq, [size(xq), vsize(2:end)]);
                end
            end
  	   end
       function yq = interpolateVector(obj, xlut, vlut, xq, ev, vcol)
		 % Interpolate a vector of data with a single vector of table values.
		 % Call out to strategy interpolate method.

           yq = zeros(numel(xq), 1, "like", obj.VLUT);
           yq(:) = ev;

           sortOutput = false;
           idx = (1:numel(xq)).';
           if ~issorted(xq)
                sortOutput = true;
                [xq,idx] = sort(xq);
            end

            % Use discretize to find the bin. Look for NaNs which means the 
            % xq value is an outlier. Since yq is pre-populated with ev, we 
            % only need to interpolate for the non-nan xq values.
            didx = discretize(xq, xlut, 'IncludedEdge','left');
            nanidx = isnan(didx);
            didxnn = didx(~nanidx);
            xlow = xlut(didxnn);
            xhigh = xlut(didxnn + 1);
            ylow = vlut(didxnn);
            yhigh = vlut(didxnn+1);
            xqnn = xq(~nanidx);
            yq(~nanidx) = obj.Interpolator.interpolate(xqnn, xhigh, xlow, yhigh, ylow, ...
                didxnn, vcol);
           yqResorted = zeros(size(yq), "like", yq);
           if sortOutput
               yqResorted(idx) = yq;
           else
               yqResorted = yq;
           end

            yq = reshape(yqResorted, size(xq));
       end
    end
    methods (Static)
	   % interp1 validation methods
        function x = validateXLut(x, funcname, varname)
            %VALIDATEXLUT Validate the X input
            validateattributes(x, {'double', 'single'}, {'vector', 'finite'}, ...
                funcname, varname);
        end

        function v = validateVLut(v, ~, ~)
            %VALIDATEVLUT Validate the V input

            % Avoid quaternion/validateattributes for performance
            coder.internal.assert(isa(v, 'quaternion'), ...
                'shared_rotations:interpolation:ExpectedFiniteQuaternions');
            coder.internal.assert(all(isfinite(v), 'all'), ...
                'shared_rotations:interpolation:ExpectedFiniteQuaternions');
        end

        function xlut = createXLut(vlut)
            %CREATEXLUT Create the X value for the lookup table
            if isvector(vlut)
                xlut = 1:numel(vlut);
            else
                xlut = 1:size(vlut,1);
            end
        end

        function xq = validateQuery(xq, funcname, varname)
            %VALIDATEQUERY Validate the query array
            validateattributes(xq, {'double', 'single'}, ...
                {'nonempty', 'nonsparse', 'finite'}, ...
                funcname, varname);
        end

        function method = validateMethod(method, ~, ~)
            %VALIDATEMETHOD Validate interpolation method
            mustBeMember(method, {...
                'slerp-short', ...
                'slerp-natural', ...
                'squad-natural', ...
                'nearest', ...
                'next', ...
                'previous'});
        end

        function ev = validateExtrapVal(ev, funcname, varname)
            %VALIDATEEXTRAPVAL Validate the extrapolation value
            validateattributes(ev, {'quaternion'}, ...
                {'scalar'}, ...
                funcname, varname);
        end
        function crossvalidateLut(x,v)
            %CROSSVALIDATELUT Ensure that X and V are appropriate sizes
            if isvector(v)
                coder.internal.assert(numel(x) == numel(v), ...
                    'shared_rotations:interpolation:LUTlengthVector');
            else
                coder.internal.assert(numel(x) == size(v,1), ...
                    'shared_rotations:interpolation:LUTlengthArray', ...
                    'NUMEL(X)', 'SIZE(V,1)');
            end
            coder.internal.assert(numel(x) >= 2, ...
                'shared_rotations:interpolation:Need2Points');
        end
        function d = defaultMethod()
            d = 'slerp-short';
        end
    
    end
end

function t = computeOutputType(x,v,xq)
if coder.target('MATLAB')
    t = superiorfloat(x,parts(v),xq);
else
    % This section is computed at compile time so there is no cost in the
    % generated code.
    xz = zeros(1,1, "like",x);
    vz = zeros(1,1, classUnderlying(v));
    xqz = zeros(1,1, "like", xq);

    t = coder.const(superiorfloat(xz, vz, xqz));
end
end
