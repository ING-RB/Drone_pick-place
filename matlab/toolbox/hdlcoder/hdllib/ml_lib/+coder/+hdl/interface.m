function interface(ioVar, interfaceName, options)
    % Specify input to be mapped to the line buffer interface in HLS
    %
    % coder.hdl.interface(inputVar, 'Line Buffer', imageSize, origin, 'Constant Fill',
    % constantFillValue) enables you to map the input variable to the line buffer
    % interface in Cadence Stratus HLS. Various properties of the line buffer
    % interface can be specified as arguments to the pragma.
    %
    % Example:
    %   function out = line_buffer_average(in1)
    %       coder.hdl.interface(in1,'Line Buffer',[20, 20],'Origin',[2, 2],'FillMethod','ConstantFill','FillValue',0);
    %       sum = 0;
    %       for i = 1:size(in1,1)
    %           for j = 1:size(in1,2)
    %               sum = sum + in1(i,j);
    %           end
    %       end
    %       out = sum / numel(in1);
    %   end
    %
    %   This is a code generation function.  It has no effect in MATLAB.

    %   Copyright 2022-2024 The MathWorks, Inc.

    %#codegen

    arguments
        ioVar (1,:) char 
        interfaceName (1,:) char {mustBeMember(interfaceName, {'Line Buffer','AXI4-Lite', 'AXI4 Master', 'AXI4-Stream'})}
        options.ImageSize (1,2) {mustBePositive}
        options.FillMethod (1,:) char {mustBeMember(options.FillMethod,{'ConstantFill', 'Reflected', 'Nearest', 'Wrap'})} = 'ConstantFill';
        options.Origin (1,2) {mustBePositive}
        options.FillValue (1,1) {mustBeNumeric}=0;
    end

   coder.columnMajor;

   if isequal(interfaceName, 'Line Buffer') 
        if ~isfield(options, 'ImageSize')        
            msg = message('hdlcoder:matlabhdlcoder:LineBufferEmptyImageSize');
            throwAsCaller(MException(msg));
        end 

    if ~isfield(options, 'Origin')
        if isequal(options.FillMethod, "Wrap")
            options.Origin = [1 1];
        else
            options.Origin = (size(ioVar) + 1)/2;
        end
    end

    if isequal(options.FillMethod, "ConstantFill")
        % Validation of 'FillValue' 

        curVal = options.FillValue;
        validBoundaryConst = isnumeric(curVal) && isscalar(curVal);

        coder.internal.assert(validBoundaryConst,...
                            'hdlmllib:hdlmllib:InvalidBoundaryConstant');
    end

    % Origin in wrap boundary fill method must be [1 1]
    if isequal(options.FillMethod, "Wrap")
            coder.internal.assert(isequal(options.Origin , [1 1]),'hdlmllib:hdlmllib:OriginProvidedInWrapMethod');
    end

   end

     if coder.target('hdl')
         if strcmp(interfaceName,'Line Buffer')
            coder.ceval('-preservearraydims', '__hdl__interface', ioVar,...
                  interfaceName, options.ImageSize(1), options.ImageSize(2),...
                  options.Origin(1), options.Origin(2),...
                  options.FillMethod, options.FillValue);
         elseif contains(interfaceName,'AXI4')
            coder.ceval('-preservearraydims', '__hdl__interface', ioVar, interfaceName); 
         end
     end
end

% LocalWords:  HLS AXI hdlmllib
