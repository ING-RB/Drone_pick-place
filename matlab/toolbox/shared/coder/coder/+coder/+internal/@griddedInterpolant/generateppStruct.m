function obj = generateppStruct(obj)
    % generate pp struct only for required methods
    % constructs pp only for 1D
    % TO DO : design a pp struct for nD methods.

    %   Copyright 2022-2024 The MathWorks, Inc.

    %#codegen
    
    if ~coder.internal.isConstTrue(isvector(obj.Values))
        coder.internal.assert(isscalar(obj.Values) || ~isvector(obj.Values) || size(obj.Values,1) ~= 1, ...
            'Coder:toolbox:interp1_vsizeMatrixBecameRowVec');
    end
    type = coder.internal.scalarEg(obj.gridVectors_{1},obj.gridValues);
    if isscalar(obj.gridVectors_)
        
        % fill ppstruct with appropriate coefficients
        % TO DO : Store CUBIC coefficients in ppstruct, will be same size
        % as pchip, spline or makima.

        % pp for interpolation method
        if coder.internal.griddedInterpolant.ppStructMethods(obj.interpMethodID)
            obj.ppStruct1DInterp = coder.internal.interpolate.interp1SplineMakimaOrPCHIPcoefs( ...
                obj.interpMethodID, obj.gridValues, obj.gridVectors_{1});
        elseif obj.interpMethodID == coder.internal.interpolate.interpMethodsEnum.CUBIC
            obj.ppStruct1DInterp = coder.internal.interpolate.interp1SplineMakimaOrPCHIPcoefs( ...
                uint8(coder.internal.interpolate.interpMethodsEnum.SPLINE), ...
                obj.gridValues, obj.gridVectors_{1});
        else
            type = coder.internal.scalarEg(obj.gridVectors_{1},obj.gridValues);
            breaks = zeros(1,0,'like',obj.gridVectors_{1});
            coefs = zeros(1,0,'like',type);
            obj.ppStruct1DInterp = struct('breaks', breaks, 'coefs', coefs);
        end

        % pp for extrapolation method
        if obj.interpMethodID == obj.extrapMethodID
            % Copies pp of interp into extrap when methods are same.
            % not an issue for small meshes. If it's a large or high
            % dimensional mesh it's a waste of space.
            % TO DO : set a flag or make sure constant folding occurs in
            % EvaluatorSwitch so that 2 copies of pp are not required.
            obj.ppStruct1DExtrap = obj.ppStruct1DInterp;
        elseif coder.internal.griddedInterpolant.ppStructMethods(obj.extrapMethodID)
            obj.ppStruct1DExtrap = coder.internal.interpolate.interp1SplineMakimaOrPCHIPcoefs( ...
                obj.extrapMethodID, obj.gridValues, obj.gridVectors_{1});
        elseif obj.extrapMethodID == coder.internal.interpolate.interpMethodsEnum.CUBIC
            obj.ppStruct1DExtrap = coder.internal.interpolate.interp1SplineMakimaOrPCHIPcoefs( ...
                uint8(coder.internal.interpolate.interpMethodsEnum.SPLINE), ...
                obj.gridValues, obj.gridVectors_{1});    
        else
            type = coder.internal.scalarEg(obj.gridVectors_{1},obj.gridValues);
            breaks = zeros(1,0,'like',obj.gridVectors_{1});
            coefs = zeros(1,0,'like',type);
            obj.ppStruct1DExtrap = struct('breaks', breaks, 'coefs', coefs);
        end
        
        if coder.target('MATLAB')
            % Convert MATLAB pp structs into coder pp structs.
            obj.ppStruct1DInterp = generatePPStructForCodegenRedirect( ...
                obj.ppStruct1DInterp);
            obj.ppStruct1DExtrap = generatePPStructForCodegenRedirect( ...
                obj.ppStruct1DExtrap);            
        end

        % Storing empties for ND coefs.
        obj.splineCoefsND = zeros(1,0,'like',type);
    else
        if obj.interpMethodID == coder.internal.interpolate.interpMethodsEnum.SPLINE || ...
                obj.extrapMethodID == coder.internal.interpolate.interpMethodsEnum.SPLINE
            % Try to get size coefs needs to have some fixed dims to work
            % with mkpp function.
            coefsSz = coder.internal.interpolate.getCoefsSize(coder.const(numel(obj.gridVectors_)), ...
                obj.gridValues);
            obj.splineCoefsND = coder.nullcopy(zeros(coefsSz,'like',obj.gridValues));
            obj.splineCoefsND = coder.internal.interpolate.generateSplineCoefsNd(numel(obj.gridVectors_), ...
                 obj.gridValues, obj.gridVectors_{:});
        elseif obj.interpMethodID == coder.internal.interpolate.interpMethodsEnum.CUBIC || ...
                obj.extrapMethodID == coder.internal.interpolate.interpMethodsEnum.CUBIC
            coefsSz = coder.internal.interpolate.getCoefsSize(coder.const(numel(obj.gridVectors_)), ...
                obj.gridValues);
            obj.splineCoefsND = coder.nullcopy(zeros(coefsSz,'like',obj.gridValues));
            obj.splineCoefsND = coder.internal.interpolate.generateSplineCoefsNd(numel(obj.gridVectors_), ...
                obj.gridValues, obj.gridVectors_{:});
        else
            obj.splineCoefsND = zeros(1,0,'like',type);
        end
        % Storing empties for 1d, We will be enforcing a limitation on
        % ndims of gridvectors and methods.
        breaks = zeros(1,0,'like',obj.gridVectors_{1});
        coefs = zeros(1,0,'like',type);
        obj.ppStruct1DInterp = struct('breaks', breaks, 'coefs', coefs); 
        obj.ppStruct1DExtrap = obj.ppStruct1DInterp;
    end
end

function pp = generatePPStructForCodegenRedirect(pp)
    % This is invoked when marshalling in a griddedInterpolant object. 
    % (passed as entry point input).
    
    if isempty(pp.breaks) || isempty(pp.coefs)
        % pp struct is not generated for this 
        % griddedInterpolant object.
        return
    end

    % MATLAB pp structs are not compatible with Coder pp structs,
    % this function converts the MATLAB pp struct into a Coder compatible
    % one.
    [breaks,coefs,~,~,d] = unmkpp(pp);

    % This is a stripped down version of the coder implementation of mkpp,
    % there is no need for error checking here.
    ndc = ndims(coefs);
    nb = numel(breaks);
    npieces = nb - 1;

    dlen = length(d);
    dlenp2 = dlen + 2;
    if ndc == 2
        order = size(coefs,2);
    else
        order = size(coefs,dlenp2);
    end
    newsize = [d,npieces,order];

    pp = coder.internal.interpolate.makepp(breaks,reshape(coefs,newsize),dlenp2);
end

% LocalWords:  vsize Vec ppstruct makima coefs extrap gridvectors
