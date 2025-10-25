classdef MatrixInverse < matlab.System
       % Compute the matrix inverse of a streaming square matrix.
       %
       % hdl.MatrixInverse creates a streaming matrix inverse System Object  
       % that computes matrix inverse by streaming the input square matrix.       
       %
       % Block parameters:
       % MatrixSize          : Size of the input matrix.
       % LatencyStrategy     : Processing latency. Can be either 'Max',
       %                       'Min' or 'Zero'. 
       % AlgorithmType       : 'GaussJordanElimination' (default): 
       %                       Inverse of a matrix computed using Gauss-Jordan
       %                       elimination method. Supports square matrices.
       %
       %                       'CholeskyDecomposition':
       %                       Inverse of a matrix computed using cholesky
       %                       decomposition method. Supports positive
       %                       definite matrices.
       %
       % Block interface:
       % Input ports:
       % dataIn              : Input data to the module.
       % validIn             : Valid signal for input data.
       % outEnable           : Input signal indicates that down stream
       %                       module is ready to take the output data from
       %                       processing module.
       % 
       % Output ports:
       % dataOut             : Output data from the module.
       % validOut            : Valid signal for output data.
       % ready               : Output signal that indicates processing
       %                       module is ready to accept the input data in
       %                       row major from upstream module.
       %
       % Example:
       % M = hdl.MatrixInverse('MatrixSize', 4, 'LatencyStrategyType', 'ZERO',...
       %                                   'AlgorithmType', 'GaussJordanElimination');
       % creates a streaming matrix inverse system object with above
       % configured parameters.
       %
       % step method syntax:
       % [dataOut,validOut,ready] = step(M,dataIn,validIn,outEnable)
       %
       %#codegen

       %   Copyright 2017-2024 The MathWorks, Inc.
    properties(Nontunable)
        %MatrixSize
        MatrixSize = 4;       
        %LatencyStrategy
        LatencyStrategyType = 'ZERO';
        %AlgorithmType
        AlgorithmType = 'GaussJordanElimination'        
    end
    
    properties(Access=protected)
        numRow
        numCol
        invRAM
        accDiagValue
        matInvMem
        inReady
        invDone
        lowerTriangValid
        fwdSubValid
        matMultValid
        outRdy
        regBufLowerTriang
        regPrev
        regBufFwdSub
        regBufMult
        readDataMultBuf
        
        %holding System object output
        countHold
        holdValid
        flagRdyLast
        flagRdyFirst
        pdataOut 
        pvalidOut
        pready
        readDataBuf
        nondiagDataOutLwrTriang
        reciprocalData
        reciprocalValid
        dataOutLowerTriang
        dataOutValidLowerTriang
        isDiagValidInLwrTriang
        isNonDiagValidInLwrTriang
        isNonDiagValidOutLwrTriang
        diagDataOutLwrTriang
        diagValidOutLwrTriang
        
        % Forward substitution
        readDataFwdSubBuf
        nonDiagFwdSubData
        dataOutFwdSub
        dataOutValidFwdSub
        accumDataFwdSub
        diagDataFwdSub
        diagValidFwdSub
        
        % Matrix multiplication
        matMultData
        dataOutMult
        dataOutValidMult
        dotMultBuf
        countOffset1
        countOffset2
        numStages
        endVal
        dataOut
        validOut
         
        %Gauss-Jordan method
        readEnable
        readEnableReg
        
        swapEnabReg
        swapDoneReg
        storeDone
        swapEnbFlag
        rowFinish
        invFinish
        
        diagValidIn
        diagValidInReg
        countEnbNonDiagVld
        countEnbNonDiagVldReg
        countEnbInternalNonDiagVld
        countEnbInternalNonDiagVldReg
        countNonDiagVld
        countNonDiagVldReg
        countInternalNonDiagVld
        countInternalNonDiagVldReg
        
        gaussJordanEnb
        gaussJordanEnbReg
        rowCountGJordan
        rowCountGJordanReg
        colCountGJordan
        colCountGJordanReg
        nonDiagValidIn
        nonDiagValidInReg
        
        diagValidInReg_f
        diagValidInReg_f_Reg
        diagValidInReg_f_count
        diagValidInReg_f_countReg
        nonDiagValidInReg_f
        nonDiagValidInReg_f_Reg
        nonDiagValidInReg_f_count
        nonDiagValidInReg_f_countReg
        diagValidOut
        diagValidOutReg
        nonDiagValidOut
        nonDiagValidOutReg
        nonDiagValidOutCount
        nonDiagValidOutCountReg
        
        diagData
        diagDataReg
        multiplyDivideInputOne
        multiplyDivideInputTwo
        subtractFirstInput
        subtractFirstInputReg
        MultiplyDivideOut
        MultiplyDivideOutReg
        subtractOut
        diagStoredData
        readData
        colCountGJordanReg_f
        colCountGJordanReg_f_Reg
        readDataProcess
        readDataProcessReg
        colCountGJordanReg_1
        colCountGJordanReg_2
        diagValidInReg_f_countReg_1
        nonDiagValidInReg_f_countReg_1
        colCountGJordanReg_f_Reg_1
        
        storedDiagZeroData
        storedDiagZeroDataReg
        colCountStoreDiagZero
        colCountStoreDiagZeroReg
        maxFinish
        maxFinishReg
        swapEnab
        swapDone
        swapEnableOut
        swapEnableOutReg
        swapAddrOut
        swapAddrOutReg
        swapDataOut
        swapDataOutReg
        
        rowCountSwapConst
        rowCountSwapConstReg 
        colCountSwapConst             
        colCountSwapConstReg 
        colCountSwapConstPrev
        colCountSwapConstPrevReg
        rdDataExtraMemSwap
        makeDiagZero
        
        multiplyDivideTwoEyeMem
        subtractFirstInputExtraMem
        subtractFirstInputExtraMemReg
        MutliplyDivideOutEyeMem
        MutliplyDivideOutEyeMemReg
        subtractOutEyeMem
        diagStoredExtraMem
        makeDataOutZero
        makeDataOutZeroReg
        makeDataOutOne
        makeDataOutOneReg
        
        swapDoneReg_1
        swapDoneReg_2
        maxColumnData
        maxColumnDataReg
        maxColCountGJordan
        maxColCountGJordanReg
        maxFinishReg_1
        
        swapReadEnable
        swapReadEnableReg
        swapReadEnableReg_1
        matInvMemGaussJordan
        invDoneReg
        inputData
    end
    
        
    properties (Constant, Hidden)        
        LatencyStrategyTypeSet = matlab.system.StringSet({...
            'ZERO',...
            'MIN',...
            'MAX'});
        AlgorithmTypeSet = matlab.system.StringSet({...
            'GaussJordanElimination',...
            'CholeskyDecomposition'});        
    end
    
    methods
        % Constructor
        function obj = MatrixInverse(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access = protected)        
        
        function num = getNumInputsImpl(~)
            % getNumInputsImpl
            % number of inputs accepted
               num = 3; 
        end % getNumInputsImpl

        function num = getNumOutputsImpl(~)
            % getNumOutputsImpl
            % number of outputs
                num  = 3;
        end % getNumOutputsImpl

        function varargout = getInputNamesImpl(obj)

            varargout = cell(1, getNumInputs(obj));
            varargout{1} = 'dataIn';
            varargout{2} = 'validIn';
            varargout{3} = 'outEnable';
        end % getInputNamesImpl

        function varargout = getOutputNamesImpl(obj)

            varargout = cell(1, getNumOutputs(obj));
            varargout{1} ='dataOut';
            varargout{2} ='validOut';
            varargout{3} = 'ready';

        end % getOutputNamesImpl        
    end
    
    

    methods(Access = protected)
        %% Validate implementation function
        function validateInputsImpl(obj, varargin)
            obj.inputData = varargin{1}; 
            % Cholesky decomposition supports only single data types
            if strcmpi(obj.AlgorithmType, 'CholeskyDecomposition')
                coder.internal.errorIf(~isa(varargin{1}, 'single'), 'hdlmllib:hdlmllib:StreamMatInvCholeskySingleOnly');
            end
            % Gauss-Jordan elimination supports only single and double data
            % types
            if strcmpi(obj.AlgorithmType, 'GaussJordanElimination')
                coder.internal.errorIf(~(isa(varargin{1}, 'single') || isa(varargin{1}, 'double')), 'hdlmllib:hdlmllib:StreamMatInvGJordanSingleAndDoubleOnly');
            end
            
            validateattributes(varargin{1}, {'numeric'}, ...
                {'real', 'scalar'},...
                'hdl.MatrixInverse', 'dataIn', 1);
            
            validateattributes(varargin{2}, {'logical'}, ...
                {'real', 'scalar'},...
                'hdl.MatrixInverse', 'validIn', 2);
            
            validateattributes(varargin{3}, {'logical'}, ...
                {'real', 'scalar'},...
                'hdl.MatrixInverse', 'outEnable', 3);             
        end % validateInputsImpl
        
        % Setup implementation function for initializing properties
        function setupImpl(obj,varargin)            
           obj.matInvMem                          = single(zeros(obj.MatrixSize,obj.MatrixSize));
           obj.nondiagDataOutLwrTriang            = single(0);  
           obj.numCol                             = uint8(1);
           obj.numRow                             = uint8(1);
           obj.isDiagValidInLwrTriang             = cast(0,'like',varargin{2});
           obj.isNonDiagValidInLwrTriang          = cast(0,'like',varargin{2});
           obj.isNonDiagValidOutLwrTriang         = cast(0,'like',varargin{2});
           obj.diagDataOutLwrTriang               = single(0);
           obj.diagValidOutLwrTriang              = cast(0,'like',varargin{2});
           obj.reciprocalData                     = single(0);
           obj.reciprocalValid                    = cast(0,'like',varargin{2});
           obj.invRAM                             = single(zeros(1,obj.MatrixSize,'like',obj.reciprocalData));
           obj.accDiagValue                       = single(0);
           obj.readDataBuf                        = single(zeros(1,obj.MatrixSize));
           obj.lowerTriangValid                   = cast(0,'like',varargin{2});
           obj.inReady                            = cast(1,'like',varargin{2});
           if obj.MatrixSize > 2
             obj.regBufLowerTriang                = single(zeros(1,obj.MatrixSize-2));
           else
             obj.regBufLowerTriang                = single(zeros(1,1));  
           end 
           obj.regPrev                            = single(zeros(1,1));
           obj.dataOutLowerTriang                 = single(zeros(1,1));
           obj.dataOutValidLowerTriang            = cast(0,'like',varargin{2});
           
           %  Initialization of Forward substitution(Linv) properties 
           obj.fwdSubValid                        = cast(0,'like',varargin{2});   
           obj.readDataFwdSubBuf                  = single(zeros(1,obj.MatrixSize));
           obj.nonDiagFwdSubData                  = single(0);
           obj.diagDataFwdSub                     = single(0);
           obj.diagValidFwdSub                    = cast(0,'like',varargin{2});
           obj.accumDataFwdSub                    = single(zeros(1,1)); 
           obj.dataOutFwdSub                      = single(zeros(1,1));
           obj.dataOutValidFwdSub                 = cast(0,'like',varargin{2});
           if obj.MatrixSize > 1
             obj.regBufFwdSub                     = single(zeros(1,obj.MatrixSize-1));
           else
             obj.regBufFwdSub                     = single(zeros(1,1));    
           end
           
           % Initialization of MatrixMultiplication(Linv'*Linv) properties
           obj.matMultValid                       = cast(0,'like',varargin{2});
           obj.matMultData                        = single(0);
           obj.readDataMultBuf                    = single(zeros(1,obj.MatrixSize));
           obj.outRdy                             = cast(0,'like',varargin{2});
           obj.invDone                            = cast(0,'like',varargin{2});
           obj.pready                             = cast(1,'like',varargin{2});
           obj.pvalidOut                          = cast(0,'like',varargin{2});
           obj.validOut                           = cast(0,'like',varargin{2});

           obj.pdataOut                           = cast(0,'like',varargin{1});
           obj.dataOut                            = cast(0,'like',varargin{1});  

           obj.countOffset1                       = uint8(2);
           obj.countOffset2                       = uint8(1);
           obj.dataOutMult                        = single(zeros(1,1));
           obj.dataOutValidMult                   = cast(0,'like',varargin{2});
           obj.regBufMult                         = single(zeros(1,obj.MatrixSize));   
           obj.dotMultBuf                         = single(zeros(1,obj.MatrixSize));
           % Deciding numStages for tree type addition            
           obj.numStages                          = ceil(log2(obj.MatrixSize));
           % Fixing endVal for tree type addition based on MatrixSize 
           if(bitand(obj.MatrixSize,1) == 1)
             obj.endVal                           = uint8(obj.MatrixSize-2);
           else
             obj.endVal                           = uint8(obj.MatrixSize-1);  
           end
           
           obj.countHold                          = uint16(0);
           obj.holdValid                          = cast(0,'like',varargin{2});
           obj.flagRdyLast                        = cast(0, 'like', varargin{2});
           obj.flagRdyFirst                       = cast(0, 'like', varargin{2});
           
           % Gauss-Jordan initialization of discrete state properties
           obj.matInvMemGaussJordan               = cast(zeros(obj.MatrixSize+obj.MatrixSize,obj.MatrixSize), 'like', varargin{1});
           obj.readEnable = cast(0, 'like', varargin{2});           
           obj.readEnableReg = cast(0, 'like', varargin{2});
           obj.swapEnabReg = cast(0, 'like', varargin{2});
           obj.swapDoneReg = cast(0, 'like', varargin{2});
           obj.swapDoneReg_1 = cast(0, 'like', varargin{2});
           obj.swapDoneReg_2 = cast(0, 'like', varargin{2});
           obj.storeDone  = cast(0,'like', varargin{2});
           obj.swapEnbFlag = cast(0,'like', varargin{2});
           obj.rowFinish = cast(0, 'like', varargin{2});
           obj.invFinish = cast(0, 'like', varargin{2});
           
           obj.diagValidIn = cast(0, 'like', varargin{2});          
           obj.diagValidInReg = cast(0, 'like', varargin{2});
           obj.countEnbNonDiagVld = cast(0, 'like', varargin{2});           
           obj.countEnbNonDiagVldReg = cast(0, 'like', varargin{2});
           obj.countEnbInternalNonDiagVld = cast(0, 'like', varargin{2});           
           obj.countEnbInternalNonDiagVldReg = cast(0, 'like', varargin{2});
           obj.countNonDiagVld  = uint8(0);
           obj.countNonDiagVldReg  = uint8(0);
           obj.countInternalNonDiagVld = uint8(0);
           obj.countInternalNonDiagVldReg = uint8(0);
           obj.gaussJordanEnb = cast(0, 'like', varargin{2});
           obj.gaussJordanEnbReg = cast(0, 'like', varargin{2});
           obj.rowCountGJordan = uint8(1);
           obj.rowCountGJordanReg = uint8(1);
           obj.colCountGJordan = uint8(1);           
           obj.colCountGJordanReg = uint8(1);
           obj.nonDiagValidIn = cast(0, 'like', varargin{2});           
           obj.nonDiagValidInReg = cast(0, 'like', varargin{2});
           obj.diagValidInReg_f = cast(0, 'like', varargin{2});           
           obj.diagValidInReg_f_Reg = cast(0, 'like', varargin{2});
           obj.diagValidInReg_f_count = uint8(1);
           obj.diagValidInReg_f_countReg = uint8(1);
           obj.nonDiagValidInReg_f = cast(0, 'like', varargin{2});
           obj.nonDiagValidInReg_f_Reg = cast(0, 'like', varargin{2});
           obj.nonDiagValidInReg_f_count = uint8(1);
           obj.nonDiagValidInReg_f_countReg = uint8(1);
           obj.diagValidOut = cast(0, 'like', varargin{2});           
           obj.diagValidOutReg = cast(0, 'like', varargin{2});
           obj.nonDiagValidOut = cast(0, 'like', varargin{2});
           obj.nonDiagValidOutReg = cast(0, 'like', varargin{2});
           obj.nonDiagValidOutCount = uint16(0);
           obj.nonDiagValidOutCountReg = uint16(0);
           
           obj.diagData = cast(0 , 'like', varargin{1});
           obj.diagDataReg = cast(0 , 'like', varargin{1});
           obj.multiplyDivideInputOne = cast(0 , 'like', varargin{1});
           obj.multiplyDivideInputTwo = cast(0 , 'like', varargin{1});
           obj.subtractFirstInput = cast(0 , 'like', varargin{1});
           obj.subtractFirstInputReg = cast(0 , 'like', varargin{1});
           obj.MultiplyDivideOut = cast(0 , 'like', varargin{1});
           obj.MultiplyDivideOutReg = cast(0 , 'like', varargin{1});
           obj.subtractOut = cast(0 , 'like', varargin{1});
           obj.diagStoredData = cast(zeros(obj.MatrixSize,1), 'like', varargin{1});
           obj.readData = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.readDataProcessReg = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.readDataProcess = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.colCountGJordanReg_f = uint8(1);
           obj.colCountGJordanReg_f_Reg = uint8(1);
           obj.colCountGJordanReg_1 = uint8(1);
           obj.colCountGJordanReg_2 = uint8(1);
           obj.diagValidInReg_f_countReg_1 = uint8(1);
           obj.nonDiagValidInReg_f_countReg_1 = uint8(1);
           obj.colCountGJordanReg_f_Reg_1 = uint8(1);
           
           obj.storedDiagZeroData = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.storedDiagZeroDataReg = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.colCountStoreDiagZero = uint8(1);
           obj.colCountStoreDiagZeroReg = uint8(1);
           obj.maxFinish = cast(0 ,'like', varargin{2});
           obj.maxFinishReg = cast(0, 'like', varargin{2});
           obj.maxFinishReg_1 = cast(0, 'like', varargin{2});
           obj.swapEnab       = cast(0, 'like', varargin{2});
           obj.swapDone       = cast(0, 'like', varargin{2});
           obj.swapEnableOut  = cast(0, 'like', varargin{2});
           obj.swapEnableOutReg = cast(0, 'like', varargin{2});
           obj.swapAddrOut      = uint8(1);
           obj.swapAddrOutReg   = uint8(1);
           obj.swapDataOut      = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.swapDataOutReg   = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           
           obj.rowCountSwapConst = uint8(0);
           obj.rowCountSwapConstReg = uint8(0);
           obj.colCountSwapConst = uint8(0);            
           obj.colCountSwapConstReg = uint8(0);
           obj.colCountSwapConstPrev = uint8(0);
           obj.colCountSwapConstPrevReg = uint8(0);
           obj.rdDataExtraMemSwap = single(0);
           obj.makeDiagZero = cast(1, 'like', varargin{2});
           obj.multiplyDivideTwoEyeMem = cast(0 , 'like', varargin{1});
           obj.subtractFirstInputExtraMem = cast(0 , 'like', varargin{1});
           obj.subtractFirstInputExtraMemReg = cast(0 , 'like', varargin{1});
           obj.MutliplyDivideOutEyeMem = cast(0 , 'like', varargin{1});
           obj.MutliplyDivideOutEyeMemReg = cast(0 , 'like', varargin{1});
           obj.subtractOutEyeMem = cast(0 , 'like', varargin{1});
           obj.diagStoredExtraMem = cast(zeros(obj.MatrixSize,1), 'like', varargin{1});   
           
           obj.makeDataOutZero = cast(0 , 'like', varargin{2});
           obj.makeDataOutZeroReg = cast(0, 'like', varargin{2});
           obj.makeDataOutOne   = cast(0, 'like', varargin{2});
           obj.makeDataOutOneReg  = cast(0, 'like', varargin{2}); 
           
           obj.maxColumnData = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.maxColCountGJordan = uint8(1);
           obj.maxColumnDataReg = cast(zeros(2*obj.MatrixSize,1), 'like', varargin{1});
           obj.maxColCountGJordanReg = uint8(1);           
           
           obj.swapReadEnable      = cast(0, 'like', varargin{2});
           obj.swapReadEnableReg   = cast(0, 'like', varargin{2});
           obj.swapReadEnableReg_1 = cast(0, 'like', varargin{2});
           obj.invDoneReg          = cast(0, 'like', varargin{2});            
        end

        function varargout = isInputDirectFeedthroughImpl(obj)
            for ii = 1:obj.getNumOutputsImpl -1
                 varargout{ii} = false;
            end
            varargout{3} = true;
        end
        %% outputImpl function for deciding output ports
        function varargout = outputImpl(obj, varargin)
            
            varargout{1}  = obj.pdataOut;           
            varargout{2}  = obj.pvalidOut;
            varargout{3}  = obj.pready; % obj.inReady
        end
        %% updateImpl function(top module)
        function updateImpl(obj,varargin)    
            
            dataIn   = varargin{1};
            validIn  = varargin{2};
            outEnb   = varargin{3};
       
            % Control for ready signal which is disabled after complete
            % matrix is stored
            obj.invDoneReg = obj.invDone;
            if obj.invDone && ~obj.inReady
               obj.inReady = cast(1,'like',validIn);
               obj.invDone = cast(0, 'like', validIn);
            elseif((obj.numRow==obj.MatrixSize)&&(obj.numCol==obj.MatrixSize) && obj.inReady && validIn)
               obj.flagRdyFirst = cast(1, 'like', validIn);
               obj.inReady      = cast(0,'like',validIn);
            elseif obj.lowerTriangValid || obj.storeDone
               obj.flagRdyFirst = cast(0, 'like', validIn);  
            end
           
            obj.pready     = obj.inReady;           
            % Control for invDone signal which is disabled when ready
            % signal is enabled
            if(obj.flagRdyLast)
               obj.invDone     = cast(1,'like',validIn);
               obj.flagRdyLast = cast(0, 'like', validIn); 
            elseif((obj.numRow==obj.MatrixSize)&&(obj.numCol==obj.MatrixSize) && obj.outRdy)
               obj.flagRdyLast = cast(1, 'like', validIn);           
            end 
            
           if strcmpi(obj.AlgorithmType, 'CholeskyDecomposition')
            % Input matrix is loaded when validIn,obj.inReady,dataAvail
            % signals are enabled
            if((validIn && obj.inReady) || obj.flagRdyFirst) 
               hdl.MatrixInverse.InputMatrixStoring(obj,dataIn,validIn);
            % Computing the lower triangular matrix(L) when lowerTriangValid
            % signal is enabled
            elseif(obj.lowerTriangValid)
               hdl.MatrixInverse.LowerTriangularComputation(obj);
            % Computing inverse of lower triangular matrix(Linv) using
            % forward substitution method when obj.fwdSubValid is enabled
            elseif(obj.fwdSubValid)
               hdl.MatrixInverse.ForwardSubstitution(obj);
            % Multiplication of transpose(Linv) with Linv when
            % obj.matMultValid is enabled
            elseif(obj.matMultValid)
               hdl.MatrixInverse.LowerTriangMatrixMult(obj);
            % Output matrix(Ainv) will be streamed when processing is
            % completed whenever obj.outRdy,outEnb signals are enabled
            elseif(obj.outRdy && outEnb)
               hdl.MatrixInverse.OutputStreaming(obj,outEnb);  
            end
            % Assigning obj.dataOut,obj.validOut signals which are
            % computed in OutputStreaming module to
            % obj.pdataOut,obj.pvalidOut signals respectively
            if(obj.outRdy && outEnb)
              obj.pdataOut   = cast(obj.dataOut,'like',obj.dataOut);
              obj.pvalidOut  = cast(obj.validOut,'like',obj.validOut);
            else
              obj.pdataOut   = single(0);
              obj.pvalidOut  = cast(0,'like',obj.outRdy);  
            end    
                                      
           %counter to keep track of column number(numCol) and row number(numRow) 
           
           % Counter for numRow and numCol when validIn,obj.inReady,dataAvail
           % signals are enabled(Input matrix storing)
           if((validIn && obj.inReady && ~obj.invDoneReg) || obj.flagRdyFirst)
                if((obj.numRow==obj.MatrixSize)&&(obj.numCol==obj.MatrixSize))
                       obj.numRow                  = cast(1,'like',obj.numRow);
                       obj.numCol                  = cast(1,'like',obj.numCol);   
                       obj.lowerTriangValid        = cast(1,'like',validIn);
                       
                       % Added run time check for throwing error message for 
                       % non-symmetric positive definite matrices
                       eigVal = eig(obj.matInvMem);
                       symPosDefinete = issymmetric(obj.matInvMem) && isempty(eigVal(eigVal <=0));    
                       coder.internal.errorIf(~symPosDefinete, 'hdlmllib:hdlmllib:UnsupportedNonSymmPositiveDefinite');
                elseif(obj.numCol==obj.MatrixSize)
                       obj.numRow = cast(obj.numRow+1,'like',obj.numRow);
                       obj.numCol = cast(1,'like',obj.numCol);
                else
                       obj.numRow = obj.numRow;
                       obj.numCol = cast(obj.numCol+1,'like',obj.numCol);  
                end
           % Counter for numRow,numCol when LowerTriangularMatrix computation 
           % is performed
           elseif(obj.lowerTriangValid)
                   if((obj.numRow==obj.MatrixSize)&&(obj.numCol== obj.MatrixSize))
                       obj.numRow            = cast(1,'like',obj.numRow);
                       obj.numCol            = cast(1,'like',obj.numCol);   
                       % obj.lowerTriangValid is disabled and obj.fwdSubValid
                       % is enabled after completion of Lower Triangular matrix 
                       % computation
                       obj.lowerTriangValid  = cast(0,'like',validIn);
                       obj.fwdSubValid       = cast(1,'like',validIn);  
                   elseif(obj.numCol== obj.numRow)
                       obj.numRow = cast(obj.numRow+1,'like',obj.numRow);
                       obj.numCol = cast(1,'like',obj.numCol);
                   else
                       obj.numRow = obj.numRow;
                       obj.numCol = cast(obj.numCol+1,'like',obj.numCol);  
                   end   
           % Counter for numRow and numCol when ForwardSubstitution  
           % module is enabled     
           elseif(obj.fwdSubValid)
                   if((obj.numRow==obj.MatrixSize)&&(obj.numCol==1))
                       obj.numRow       = cast(1,'like',obj.numRow);
                       obj.numCol       = cast(1,'like',obj.numCol);   
                       % fwdSubValid is disabled and obj.matMultValid is enabled
                       % after completion of Forward substitution module
                       obj.fwdSubValid  = cast(0,'like',validIn);
                       obj.matMultValid   = cast(1,'like',validIn);  
                   elseif(obj.numCol==1)
                       obj.numRow = cast(obj.numRow+1,'like',obj.numRow);
                       obj.numCol = cast(obj.numRow,'like',obj.numCol);
                   else
                       obj.numRow = obj.numRow;
                       obj.numCol = cast(obj.numCol-1,'like',obj.numCol);  
                   end
           % Counter for numRow and numCol when LowerTriangularMatMult((Linv)'*Linv) 
           % module is enabled     
           elseif(obj.matMultValid)
                   if((obj.numRow==obj.MatrixSize)&&(obj.numCol==obj.MatrixSize) && obj.matMultValid)
                       obj.numRow          = cast(1,'like',obj.numRow);
                       obj.numCol          = cast(1,'like',obj.numCol);                  
                       % obj.matMultValid is disabled and obj.outRdy signal 
                       % is enabled a when matrix multiplication(transpose(Linv)*Linv) 
                       % is completed
                       obj.holdValid       = cast(1, 'like', obj.holdValid);
                       obj.matMultValid    = cast(0,'like',obj.matMultValid);
                   elseif(obj.numCol==obj.MatrixSize && obj.matMultValid)
                       obj.numRow          = cast(obj.numRow+1,'like',obj.numRow);
                       obj.numCol          = cast(obj.numRow,'like',obj.numCol);              
                   elseif(obj.matMultValid)
                       obj.numRow          = obj.numRow;
                       obj.numCol          = cast(obj.numCol+1,'like',obj.numCol); 
                   end
           elseif(obj.holdValid)
                obj.countHold = cast(obj.countHold+1, 'like', obj.countHold);
                    
                if(obj.countHold == obj.getLatency)   % Zero Latency 82 -4X4
                   obj.holdValid       = cast(0, 'like', obj.holdValid);
                   obj.outRdy          = cast(1,'like',obj.outRdy);
                   obj.countHold       = cast(0, 'like', obj.countHold);
                end    
           % Counter for numRow,numCol when OutputStreaming module is enabled 
           % when obj.outRdy,outEnb signals are high
           elseif(obj.outRdy && outEnb)
                   if((obj.numRow==obj.MatrixSize)&&(obj.numCol==obj.MatrixSize))
                       obj.numRow    = cast(1,'like',obj.numRow);
                       obj.numCol    = cast(1,'like',obj.numCol);   
                       % obj.outRdy signal is disabled when OutputStreaming
                       % module is completed
                       obj.outRdy                  = cast(0,'like',obj.outRdy);   
                   elseif(obj.numCol==obj.MatrixSize)
                       obj.numRow = cast(obj.numRow+1,'like',obj.numRow);
                       obj.numCol = cast(1,'like',obj.numCol);
                   else
                       obj.numRow = obj.numRow;
                       obj.numCol = cast(obj.numCol+1,'like',obj.numCol);  
                   end              
           end
           end
           % Gauss-Jordan
           if strcmpi(obj.AlgorithmType, 'GaussJordanElimination')
               hdl.MatrixInverse.InputMatrixStoringGJordan(obj, dataIn, validIn);
               hdl.MatrixInverse.GaussJordanEnable(obj);
               hdl.MatrixInverse.GaussJordanReadEnable(obj);
               hdl.MatrixInverse.GaussJordanColCounter(obj);
               hdl.MatrixInverse.GaussJordanRowCounter(obj);
               hdl.MatrixInverse.GaussJordanDataValidIn(obj);
               hdl.MatrixInverse.SwappingLogic(obj);
               hdl.MatrixInverse.DiagNonDiagProcessing(obj);
               hdl.MatrixInverse.OutputStreamingGJordan(obj,outEnb);
                              
               if(obj.outRdy && outEnb)
                   obj.pdataOut   = cast(obj.dataOut,'like',obj.dataOut);
                   obj.pvalidOut  = cast(obj.validOut,'like',obj.validOut);
               else
                   obj.pdataOut   = cast(0, 'like', obj.pdataOut);
                   obj.pvalidOut  = cast(0,'like',obj.outRdy);
               end
               if((validIn && obj.inReady && ~obj.invDoneReg) || obj.flagRdyFirst)
                   if((obj.numRow==obj.MatrixSize)&&(obj.numCol==obj.MatrixSize))
                       obj.numRow    = cast(1,'like',obj.numRow);
                       obj.numCol    = cast(1,'like',obj.numCol);
                       obj.storeDone = cast(1, 'like', validIn);
                   elseif(obj.numCol==obj.MatrixSize)
                       obj.numRow = cast(obj.numRow+1,'like',obj.numRow);
                       obj.numCol = cast(1,'like',obj.numCol);
                   else
                       obj.numRow = obj.numRow;
                       obj.numCol = cast(obj.numCol+1,'like',obj.numCol);
                   end
                   
               elseif(obj.holdValid)
                   obj.countHold = cast(obj.countHold+1, 'like', obj.countHold);
                   if(obj.countHold == obj.getLatency)
                       obj.holdValid       = cast(0, 'like', obj.holdValid);
                       obj.outRdy          = cast(1,'like',obj.outRdy);
                       obj.countHold       = cast(0, 'like', obj.countHold);
                   end
                   % Counter for numRow,numCol when OutputStreaming module is enabled
                   % when obj.outRdy,outEnb signals are high
               elseif(obj.outRdy && outEnb)
                   if((obj.numRow==obj.MatrixSize)&&(obj.numCol==obj.MatrixSize))
                       obj.numRow    = cast(1,'like',obj.numRow);
                       obj.numCol    = cast(1,'like',obj.numCol);
                       % obj.outRdy signal is disabled when OutputStreaming
                       % module is completed
                       obj.outRdy                  = cast(0,'like',obj.outRdy);
                   elseif(obj.numCol==obj.MatrixSize)
                       obj.numRow = cast(obj.numRow+1,'like',obj.numRow);
                       obj.numCol = cast(1,'like',obj.numCol);
                   else
                       obj.numRow = obj.numRow;
                       obj.numCol = cast(obj.numCol+1,'like',obj.numCol);
                   end
                   
               end
           end
        end
 
        function resetImpl(~)
            % Initialize / reset discrete-state properties           
        end        

        %% Backup/restore functions
        function s = saveObjectImpl(obj)
            % Set properties in structure s to values in object obj

            % Set public properties and states
            s = saveObjectImpl@matlab.System(obj);

            % Set private and protected properties
            %s.myproperty = obj.myproperty;
        end

        function loadObjectImpl(obj,s,wasLocked)
            % Set properties in object obj to values in structure s

            % Set private and protected properties
            % obj.myproperty = s.myproperty; 

            % Set public properties and states
            loadObjectImpl@matlab.System(obj,s,wasLocked);
        end
 
        % Supporting in resettable subsystem
        function modes = getExecutionSemanticsImpl(obj) %#ok<MANU>
            % supported semantics
            modes = {'Classic', 'Synchronous'};
        end % getExecutionSemanticsImpl
        
        % Supporting in For-Each subsystem
        function supported = supportsMultipleInstanceImpl(~)
            % Support in For Each Subsystem
            supported = true;
        end        

        %% Simulink functions
        function ds = getDiscreteStateImpl(~)
            % Return structure of properties with DiscreteState attribute
            ds = struct([]);
        end

        function flag = isInputSizeMutableImpl(~,~)
            % Return false if input size is not allowed to change while
            % system is running
            flag = false;
        end
        
        function validatePropertiesImpl(obj)            
            % Matrices size should be in between 1 and 64
            if(~(obj.MatrixSize > 0 && obj.MatrixSize <= 64))
                error('Matrix size should be in between 1 and 64');
            end           
        end

        function [out,out1,out2] = getOutputSizeImpl(obj)
            % Return size for each output port
            out = propagatedInputSize(obj,1);
            out1 = [1 1];
            out2 = [1 1];
            % Example: inherit size from first input port
            % out = propagatedInputSize(obj,1);
        end

        function [out,out1,out2] = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            out  = propagatedInputDataType(obj,1);
            out1 = propagatedInputDataType(obj,2);
            out2 = propagatedInputDataType(obj,2);
        end

        function [out,out1,out2] = isOutputComplexImpl(~)
            % Return true for each output port with complex data
            out  = false;
            out1 = false;
            out2 = false;
            % Example: inherit complexity from first input port
            % out = propagatedInputComplexity(obj,1);
        end

        function [out,out1,out2] = isOutputFixedSizeImpl(~)
            % Return true for each output port with fixed size
            out  = true;
            out1 = true;
            out2 = true;
            % Example: inherit fixed-size status from first input port
            % out = propagatedInputFixedSize(obj,1);
        end
        


        function icon = getIconImpl(obj)
            % Return text as string or cell array of strings for the System
            % block icon
            if strcmpi(obj.AlgorithmType, 'CholeskyDecomposition')
                icon = sprintf('MatrixInverse:Cholesky\n processingLatency: %d',obj.getLatency + ((3*obj.MatrixSize*(obj.MatrixSize+1)))/2);
            elseif strcmpi(obj.AlgorithmType, 'GaussJordanElimination')
                icon = sprintf('MatrixInverse:Gauss-Jordan\n processingLatency: %d',obj.getLatency +...
                    ((2*(obj.MatrixSize*obj.MatrixSize*obj.MatrixSize)) + (obj.MatrixSize*obj.MatrixSize)+(21*obj.MatrixSize))/2);
            end            
        end
 
        function latency = getLatency(obj)
            
            if(strcmpi(obj.LatencyStrategyType, 'MAX'))
                addLatency   = 11;
                mulLatency   = 8;
                sqrtLatency  = 28;
                recipLatency = 31;
            elseif(strcmpi(obj.LatencyStrategyType, 'MIN'))
                addLatency   = 6;
                mulLatency   = 6;
                sqrtLatency  = 16;
                recipLatency = 16;
            else
                addLatency   = 0;
                mulLatency   = 0;
                sqrtLatency  = 0;
                recipLatency = 0;
            end

            if strcmpi(obj.AlgorithmType, 'CholeskyDecomposition')
                latency = ((2*mulLatency + 3*addLatency+3)*(obj.MatrixSize*obj.MatrixSize)+...
                    (4*mulLatency+7*addLatency+2*sqrtLatency+2*recipLatency+27)*(obj.MatrixSize)+...
                    -(2*mulLatency+2*addLatency-2) + 2*addLatency*ceil(log2(obj.MatrixSize)))/2;
            
            elseif strcmpi(obj.AlgorithmType, 'GaussJordanElimination')
                n = obj.MatrixSize;
                if isa(obj.inputData, 'single') || isa(obj.diagData, 'single')
                    if strcmpi(obj.LatencyStrategyType, 'MAX')
                        if obj.MatrixSize == 1
                            latency = 35;
                        else
                            latency = ((3*n*n) +(107*n)+8)/2;
                        end
                    elseif strcmpi(obj.LatencyStrategyType, 'MIN')
                        if obj.MatrixSize == 1
                            latency = 18;
                        else
                            latency = (n*(n+61))/2;
                        end
                    else
                        latency = 0;
                    end
                else
                    if strcmpi(obj.LatencyStrategyType, 'MAX')
                        if obj.MatrixSize == 1
                            latency = 64;
                        else
                            latency = (((3*n*n) +(107*n)+8)/2) + 30*n;
                        end
                    elseif strcmpi(obj.LatencyStrategyType, 'MIN')
                        if obj.MatrixSize == 1
                            latency = 32;
                        else
                            latency = ((n*(n+61))/2) + 14*n;
                        end
                    else
                        latency = 0;
                    end
                end
            end
        end
    end
    %% Function for displaying input/output and optional ports 
    methods (Static, Access = protected)
        function header = getHeaderImpl
            header = matlab.system.display.Header('hdl.MatrixInverse',...
                'Title','Matrix Inverse [Stream]');
        end         
        
        function groups = getPropertyGroupsImpl
           parametersGroup = matlab.system.display.Section(...
             'Title','Parameters',...
             'PropertyList',{'MatrixSize','LatencyStrategyType', 'AlgorithmType'});           
         
           groups = parametersGroup;
        end
        
        function flag = showSimulateUsingImpl
             flag = false;
        end    
    end
    %% This method contains matrix inverse sub modules
    methods (Static, Access=private)
        
        % Input matrix storing
        function InputMatrixStoring(obj,dataIn,validIn)
            if((validIn && obj.inReady && ~obj.invDoneReg) || obj.flagRdyFirst)
                obj.matInvMem(obj.numRow,obj.numCol)  = cast(dataIn,'like',dataIn);                             
            end
        end
        
        % Lower triangular matrix computation(L)
        function  LowerTriangularComputation(obj)
    
            % Lower Triangular Matrix computation
            % diagonal elements computation in LT matrix
            % isDiagValidInLwrTriang property is enabled when Row index is equals to
            % Column index
            if(obj.numRow==obj.numCol && obj.lowerTriangValid)
               obj.isDiagValidInLwrTriang = cast(1,'like',obj.lowerTriangValid);
            else
               obj.isDiagValidInLwrTriang = cast(0,'like',obj.lowerTriangValid);
            end
            % compute square root of diagonal element when numRow and
            % numCol are equals to 1 otherwise compute square root of
            % subtracted data between dataIn and accumulation of squares of
            % Non diagonal elements
            if(obj.isDiagValidInLwrTriang==true)
                if(obj.numCol==1)
                   obj.diagDataOutLwrTriang             = cast((sqrt(abs(obj.matInvMem(obj.numRow,obj.numCol)))),'like',obj.diagDataOutLwrTriang);
                else
                   obj.diagDataOutLwrTriang             = cast((sqrt(abs(obj.matInvMem(obj.numRow,obj.numCol)-(obj.accDiagValue)))),'like',obj.diagDataOutLwrTriang);
                   obj.matInvMem(obj.numRow,obj.numCol) = cast(obj.diagDataOutLwrTriang,'like',obj.diagDataOutLwrTriang); 
                end
                obj.diagValidOutLwrTriang               = cast(1,'like',obj.lowerTriangValid);
            else
                obj.diagDataOutLwrTriang                = cast(0,'like',obj.diagDataOutLwrTriang);
                obj.diagValidOutLwrTriang               = cast(0,'like',obj.lowerTriangValid);
            end 
            % compute inverse(reciprocal(1/x)) of diagonal element
            if(obj.isDiagValidInLwrTriang==true)
                
                if(obj.diagDataOutLwrTriang == 0)
                 obj.reciprocalData                      = cast(0,'like',obj.diagDataOutLwrTriang); 
                else
                 obj.reciprocalData                      = cast((1/obj.diagDataOutLwrTriang),'like',obj.diagDataOutLwrTriang); 
                end
                obj.reciprocalValid                      = cast(1,'like',obj.lowerTriangValid);
            else
                obj.reciprocalData                      = cast(0,'like',obj.diagDataOutLwrTriang);
                obj.reciprocalValid                     = cast(0,'like',obj.lowerTriangValid);
            end 
            % storing of reciprocal of diagonal elements into Register buffer
            if(obj.reciprocalValid==true)
                obj.invRAM(obj.numCol)                  = cast(obj.reciprocalData,'like',obj.reciprocalData);
            end 
            
            % Non-Diagonal elements computation signal isNonDiagValidInLwrTriang when
            % numRow is greater than numCol
            if(obj.numCol<obj.numRow && obj.lowerTriangValid)
               obj.isNonDiagValidInLwrTriang = cast(1,'like',obj.lowerTriangValid);
            else
               obj.isNonDiagValidInLwrTriang = cast(0,'like',obj.lowerTriangValid);
            end

            % Reading previous non diagonal elements from LT memory for computation of
            % current non diagonal element and store the read data values
            % into read data buffer(readDataBuf)
            for i = obj.numCol:obj.numRow-1
                if (obj.numRow >=3 && obj.numCol>=2) && obj.lowerTriangValid
                      obj.readDataBuf(i)      = cast(obj.matInvMem(i,obj.numCol-1),'like',obj.matInvMem(i,obj.numCol-1));
                else
                      obj.readDataBuf      = obj.readDataBuf;
                end
            end
          
            %Finding the individual non diagonal elements multiplications
            %and accumulations(intermediate results),then updating into register buffer
            %respectively for each element in a Row up to diagonal element    

            % Multiplication and accumulation
            if(obj.numCol<obj.numRow && obj.lowerTriangValid)
             for k = obj.numCol:obj.numRow-1 
                if (obj.numRow >= 3 && obj.numCol >= 2)
                     obj.regBufLowerTriang(k-1)                  =  cast(obj.regBufLowerTriang(k-1)   + obj.regPrev * obj.readDataBuf(k),'like',obj.regBufLowerTriang(k-1)); 
                elseif obj.numCol == 1
                     obj.regBufLowerTriang(1:obj.MatrixSize-2)   =  cast(0,'like',obj.regBufLowerTriang(1));                   
                else
                     obj.regBufLowerTriang(k)                    =  obj.regBufLowerTriang(k);
                end    
             end
            end

            % Updating regPrev value by multiplying dataIn with dataInv value
            % when obj.numCol is equals to 1 otherwise RegBuf(obj.numCol-1) value
            % from dataIn and multiplying with dataInv value. This
            % obj.regPrev value will be non diagonal element data in lower
            % triangular matrix
            if(obj.numCol<obj.numRow && obj.lowerTriangValid)
             if obj.numCol == 1 
                obj.regPrev  = cast(obj.matInvMem(obj.numRow,obj.numCol) * obj.invRAM(obj.numCol),'like',obj.regPrev);
             elseif obj.numCol < obj.MatrixSize
                obj.regPrev  = cast((obj.matInvMem(obj.numRow,obj.numCol)-obj.regBufLowerTriang(obj.numCol-1)) * obj.invRAM(obj.numCol),'like',obj.regPrev);
             end
            end
            % Storing non diagonal data into memory 
            if(obj.isNonDiagValidInLwrTriang==true && obj.lowerTriangValid)
               obj.matInvMem(obj.numRow,obj.numCol) = cast(obj.regPrev,'like',obj.regPrev);
               obj.isNonDiagValidOutLwrTriang       = cast(1,'like',obj.lowerTriangValid);
            else
               obj.isNonDiagValidOutLwrTriang       = cast(0,'like',obj.lowerTriangValid);
            end
            
            % Accumulation of squares of NonDiagonal elements to calculate diagonal elements
            if((obj.isNonDiagValidOutLwrTriang == true) && obj.lowerTriangValid)
               obj.accDiagValue = obj.accDiagValue + (obj.regPrev*obj.regPrev);
            elseif(obj.numCol == obj.numRow)
               obj.accDiagValue = single(0);
            else
               obj.accDiagValue = obj.accDiagValue;
            end
        end
        
        % Computation of inverse of Lower triangular matrix(Linv) using
        % Forward Substitution method
        function  ForwardSubstitution(obj)
            
            % Diagonal elements computation in Linv
           
            % Assigning the diagonal elements in Linv will be equals to
            % reciprocal of diagonal elements in L matrix(which are stored
            % in invRAM register buffer)
            if  obj.fwdSubValid && (obj.numRow == obj.numCol)
               obj.diagDataFwdSub                     = obj.invRAM(obj.numCol);
               obj.matInvMem(obj.numRow,obj.numCol)   = obj.diagDataFwdSub; 
               obj.diagValidFwdSub                    = cast(1,'like',obj.fwdSubValid);
            elseif obj.fwdSubValid
               obj.diagDataFwdSub                     = obj.diagDataFwdSub;
               obj.diagValidFwdSub                    = cast(0,'like',obj.fwdSubValid);
            end
           
            % Reading previous non diagonal elements of Linv from  memory 
            % and stored into read data buffer(readDataFwdSubBuf) for computation of current non diagonal element when fwdSubValid
            % property is enabled
            for l = obj.numCol:-1:1
              if obj.numRow > obj.numCol && obj.fwdSubValid 
                 obj.readDataFwdSubBuf(l)          = cast(obj.matInvMem(l,obj.numCol),'like',obj.matInvMem(l,obj.numCol));
              elseif obj.fwdSubValid
                 obj.readDataFwdSubBuf          = obj.readDataFwdSubBuf;
              end
            end        
            
            %Finding the individual non diagonal elements multiplications
            %and accumulations(intermediate results),then updating into register buffer
            %respectively for each element in a Row up to diagonal element    

            % Multiplication and accumulation
            if  obj.fwdSubValid && (obj.numRow > obj.numCol)
             for k = obj.numCol:-1:1 
                if (obj.numRow > obj.numCol) && obj.fwdSubValid
                     if k == obj.numCol
                       obj.regBufFwdSub(k)       =  cast(obj.regBufFwdSub(k)   + obj.matInvMem(obj.numRow,obj.numCol) * obj.readDataFwdSubBuf(k),'like',obj.regBufFwdSub(k));                    
                       obj.accumDataFwdSub       =  cast(obj.regBufFwdSub(k),'like',obj.regBufFwdSub(k));
                       obj.regBufFwdSub(k)       =  cast(0,'like',obj.regBufFwdSub(k));
                     else
                       obj.regBufFwdSub(k)       =  cast(obj.regBufFwdSub(k)   + obj.matInvMem(obj.numRow,obj.numCol) * obj.readDataFwdSubBuf(k),'like',obj.regBufFwdSub(k));    
                     end
                else
                     obj.regBufFwdSub         = obj.regBufFwdSub;
                end    
             end
            end
            % Updating obj.nonDiagFwdSubData by multiplying reciprocal of 
            % diagonal element data of L(obj.invRAM(obj.numRow)) with obj.accumDatawdSub
            if obj.numRow > obj.numCol && obj.fwdSubValid
                if obj.invRAM(obj.numRow) == 0 || obj.accumDataFwdSub == 0
                    obj.nonDiagFwdSubData         = cast(0,'like',obj.dataOutFwdSub);
                else
                    obj.nonDiagFwdSubData         = cast(-obj.invRAM(obj.numRow) * obj.accumDataFwdSub,'like',obj.dataOutFwdSub);
                end
                obj.matInvMem(obj.numRow,obj.numCol)     =  cast(obj.nonDiagFwdSubData,'like',obj.nonDiagFwdSubData);
                obj.matInvMem(obj.numCol,obj.numRow)     =  cast(obj.nonDiagFwdSubData,'like',obj.nonDiagFwdSubData);    
                
            else
                obj.nonDiagFwdSubData         = cast(0,'like',obj.dataOutFwdSub);
            end
        end
        
        % Matrix multiplication of transpose of Linv(Linv') and Linv
        function LowerTriangMatrixMult(obj)
            
            % Reading every column elements(numCol to MatrixSize) from memory 
            % and store these elements into register buffer(readDataMultBuf)
            for p = obj.numCol:obj.MatrixSize
                if(obj.matMultValid)
                  obj.readDataMultBuf(p) = cast(obj.matInvMem(p,obj.numCol),'like',obj.readDataMultBuf(p));
                else  
                  obj.readDataMultBuf = obj.readDataMultBuf;
                end
                % Replacing the readDataMultBuf's index(from 1 to numCol-1) with zero's 
                if (obj.matMultValid && obj.numCol>1)
                  obj.readDataMultBuf(1:obj.numCol-1) = cast(0,'like',obj.readDataMultBuf(1));  
                end    
            end
            
            % Updating RegBuf with readDataBuf when RowIndex is equals to
            % ColumnIndex
            if obj.numCol == obj.numRow && obj.matMultValid
                obj.regBufMult(1:end)             = cast(obj.readDataMultBuf(1:end),'like',obj.regBufMult(1));
            elseif obj.matMultValid
                obj.regBufMult(1:end)             = obj.regBufMult(1:end);
            end
            
            % Performing element wise multiplication between RegBuf and readDataBuf using
            % dot product(.*) operator
            if obj.matMultValid && obj.numCol >= obj.numRow
                obj.dotMultBuf               = cast(obj.regBufMult(1:end) .* obj.readDataMultBuf(1:end),'like',obj.dotMultBuf);     
                % Perform addition of all the elements in dotMultBuf by
                % adding two at a time(tree structure) depending upon
                % number of pipeline stages(obj.numStages)
                for i =1:obj.numStages
                 for j = 1:obj.countOffset1:obj.endVal
                   if((j+obj.countOffset2)<=obj.MatrixSize)
                     obj.dotMultBuf(j) = obj.dotMultBuf(j) + obj.dotMultBuf(j+obj.countOffset2);
                   end
                 end    
                 obj.countOffset1 = cast(obj.countOffset1 * 2,'like',obj.countOffset1);
                 obj.countOffset2 = cast(obj.countOffset2 * 2,'like',obj.countOffset2);
                end
                obj.countOffset1             = cast(2,'like',obj.countOffset1);
                obj.countOffset2             = cast(1,'like',obj.countOffset2);
                % Storing added result into matinvMem
                obj.matInvMem(obj.numRow,obj.numCol) = cast(obj.dotMultBuf(1),'like',obj.dotMultBuf(1));
                obj.matInvMem(obj.numCol,obj.numRow) = cast(obj.dotMultBuf(1),'like',obj.dotMultBuf(1));
            end
        end
        
        % Streaming output matrix(Ainv) after processing is done
        function  OutputStreaming(obj,outEnb)
            % After completion of last stage of Matrix Inverse(Matrix
            % multiplication of Linv' and Linv) dataOut is streaming out with validOut 
            % when outEnb and obj.outReady signals are enabled
            if(obj.outRdy && outEnb)
                obj.dataOut   = cast(obj.matInvMem(obj.numRow,obj.numCol),'like',obj.matInvMem(obj.numRow,obj.numCol));
                obj.validOut  = cast(1,'like',obj.outRdy);
            else
                obj.dataOut   = single(0);
                obj.validOut  = cast(0,'like',obj.outRdy);
            end
        end

%% Gauss Jordan Matrix Inverse

        function InputMatrixStoringGJordan(obj,dataIn,validIn)
            % Storing the input streaming data into memory(A to I) 
            if((validIn && obj.inReady && ~obj.invDoneReg) || obj.flagRdyFirst)
                obj.matInvMemGaussJordan(obj.numCol, obj.numRow)  = cast(dataIn,'like',dataIn);
            end
            % Storing Identity matrix data into memory(I to Ainv) while
            % loading input data
            if((validIn && obj.inReady && ~obj.invDoneReg) || obj.flagRdyFirst ) && (obj.numRow == obj.numCol)
                obj.matInvMemGaussJordan(obj.numRow+obj.MatrixSize,obj.numCol)  = cast(1,'like',dataIn);
            elseif ((validIn && obj.inReady && ~obj.invDoneReg) || obj.flagRdyFirst ) && (obj.numRow ~= obj.numCol)
                obj.matInvMemGaussJordan(obj.numRow+obj.MatrixSize,obj.numCol)  = cast(0,'like',dataIn);
            end
        end        
        
        % gaussJordanEnb signal will be enabled through out the processing
        % module
        function GaussJordanEnable(obj)
            obj.gaussJordanEnbReg = obj.gaussJordanEnb;            
            if obj.storeDone
                obj.gaussJordanEnb = true;               
            elseif obj.invFinish
                obj.gaussJordanEnb = false;
            else
                obj.gaussJordanEnb = obj.gaussJordanEnbReg;
            end    

        end
        
        function GaussJordanReadEnable(obj)
                        
            % row data by reading it from memory
            if obj.colCountGJordanReg <= obj.MatrixSize
               obj.readData = obj.matInvMemGaussJordan(:, obj.colCountGJordanReg);
            else
               obj.readData = obj.readData;  
            end
            
            obj.readEnableReg = obj.readEnable;
            obj.countEnbNonDiagVldReg = obj.countEnbNonDiagVld;
            obj.countNonDiagVldReg = obj.countNonDiagVld;
            obj.countEnbInternalNonDiagVldReg = obj.countEnbInternalNonDiagVld;
            obj.countInternalNonDiagVldReg = obj.countInternalNonDiagVld;
            
            obj.nonDiagValidOutReg = obj.nonDiagValidOut;
            obj.nonDiagValidOutCountReg  = obj.nonDiagValidOutCount;
            
            obj.diagValidOutReg = obj.diagValidOut;
            
            obj.colCountGJordanReg_2 = obj.colCountGJordanReg_1;
            obj.colCountGJordanReg_1 = obj.colCountGJordanReg;
            obj.colCountGJordanReg = obj.colCountGJordan;
            obj.rowCountGJordanReg = obj.rowCountGJordan;
            
            
            obj.colCountStoreDiagZeroReg = obj.colCountStoreDiagZero;
            obj.storedDiagZeroDataReg    = obj.storedDiagZeroData;
            obj.swapEnabReg = obj.swapEnab;
            
            obj.swapDoneReg_2 = obj.swapDoneReg_1;
            obj.swapDoneReg_1 = obj.swapDoneReg;
            obj.swapDoneReg = obj.swapDone;
            obj.maxFinishReg_1 = obj.maxFinishReg;
            obj.maxFinishReg = obj.maxFinish;
            obj.swapEnableOutReg = obj.swapEnableOut;
            obj.swapAddrOutReg = obj.swapAddrOut;    
            obj.swapDataOutReg = obj.swapDataOut;
            obj.maxColumnDataReg      = obj.maxColumnData;
            obj.maxColCountGJordanReg = obj.maxColCountGJordan;             
            
            obj.diagValidInReg = obj.diagValidIn; 
            obj.nonDiagValidInReg = obj.nonDiagValidIn; 
            
            %rowFinish            
            if obj.MatrixSize == 1 
                obj.rowFinish = obj.diagValidOutReg; %&& obj.diagValidOutCountReg == uint16(1);% N=1
            elseif  obj.MatrixSize == 2
                obj.rowFinish = obj.nonDiagValidOutReg && (obj.nonDiagValidOutCountReg == ((obj.MatrixSize*(obj.MatrixSize-1))-1));%N=2
            else
                obj.rowFinish = obj.nonDiagValidOutReg && (obj.nonDiagValidOutCountReg == ((obj.MatrixSize*(obj.MatrixSize-1))-2));%N>2                
            end
            
            obj.invFinish = obj.rowFinish && (obj.rowCountGJordanReg == obj.MatrixSize);            
            
            obj.swapReadEnableReg_1 = obj.swapReadEnableReg;
            obj.swapReadEnableReg = obj.swapReadEnable;           
            
            % readEnable signal which will be used to increment the read
            % address
            if obj.invFinish
                obj.readEnable = false;
            elseif obj.swapDoneReg ||obj.swapReadEnableReg || obj.storeDone || obj.rowFinish
                obj.readEnable= true;
            elseif (obj.diagValidInReg_f_countReg == obj.MatrixSize-1) && obj.diagValidInReg_f_Reg
                obj.readEnable = true;
            elseif obj.countEnbNonDiagVldReg && obj.MatrixSize > 2
                obj.readEnable = true;                
            else
                obj.readEnable = false;
            end
                      
            % countEnbNonDiagVld flag will be used to generate readEnable signal for 
            % non-diagonal elements calculation 
            if obj.countInternalNonDiagVldReg == obj.MatrixSize-2
                obj.countEnbNonDiagVld = true;
            else
                obj.countEnbNonDiagVld = false;
            end    
            % countNonDiagVld is the counter used while
            % nonDiagonalValidSignal generation
            if obj.countEnbNonDiagVldReg && obj.countNonDiagVldReg == obj.MatrixSize-3
                obj.countNonDiagVld = cast(0, 'like', obj.countNonDiagVld);            
            elseif obj.countEnbNonDiagVldReg
                obj.countNonDiagVld = obj.countNonDiagVldReg + 1;
            else
                obj.countNonDiagVld = obj.countNonDiagVldReg;
            end
            
            % countEnbInternalNonDiagVld is the enable signal to increment
            % internal counter for nonDiagonalValidIn
            if obj.diagValidInReg_f_countReg == obj.MatrixSize 
                obj.countEnbInternalNonDiagVld = true;
            elseif obj.countInternalNonDiagVldReg == obj.MatrixSize-1 && obj.countNonDiagVldReg == obj.MatrixSize-3 && obj.countEnbInternalNonDiagVldReg
                obj.countEnbInternalNonDiagVld = false;
            else
                obj.countEnbInternalNonDiagVld = obj.countEnbInternalNonDiagVldReg;  
            end
           
            % countInternalNonDiagVld will increment when
            % countEnbInternalNonDiagVld signal is 'on' 
            if obj.countEnbInternalNonDiagVldReg && obj.countInternalNonDiagVldReg == obj.MatrixSize-1
                obj.countInternalNonDiagVld = cast(0, 'like', obj.countInternalNonDiagVld);            
            elseif obj.countEnbInternalNonDiagVldReg
                obj.countInternalNonDiagVld = obj.countInternalNonDiagVldReg + 1;
            else
                obj.countInternalNonDiagVld = obj.countInternalNonDiagVldReg;
            end

        end

        function GaussJordanColCounter(obj)
                       
            makeColCntOne = obj.readEnableReg && ((obj.colCountGJordanReg == obj.MatrixSize-1 && obj.rowCountGJordanReg == obj.MatrixSize)...
                                                  || ((obj.colCountGJordanReg == obj.rowCountGJordanReg) && obj.rowCountGJordanReg ~= 1));
            incrColCntTwo = (obj.colCountGJordanReg == obj.rowCountGJordanReg-1) && obj.readEnableReg;
            incrColCntOne = (obj.colCountGJordanReg < obj.MatrixSize && obj.readEnableReg) || obj.swapReadEnableReg; %obj.swapEnabReg; 
            
            obj.swapEnbFlag = obj.diagValidInReg && ~obj.swapDoneReg_2;
           
            % colCounter which will be read address for memory
            if obj.swapDoneReg
                obj.colCountGJordan = obj.rowCountGJordanReg;
            elseif makeColCntOne || obj.invFinish
                obj.colCountGJordan = cast(1, 'like', obj.colCountGJordan);
            elseif (obj.rowFinish && obj.colCountGJordanReg == obj.MatrixSize) || obj.swapEnbFlag
                obj.colCountGJordan = obj.rowCountGJordanReg + 1;
            elseif incrColCntTwo
                obj.colCountGJordan = obj.colCountGJordanReg + 2;
            elseif incrColCntOne
                obj.colCountGJordan = obj.colCountGJordanReg + 1;
            else
                obj.colCountGJordan = obj.colCountGJordanReg;
            end

        end
        
        function GaussJordanRowCounter(obj)
            
            % rowCounter which will be incremented whenever the processing of one 
            % complete row is finished
            if (obj.rowFinish && obj.rowCountGJordanReg == obj.MatrixSize && obj.colCountGJordanReg == obj.MatrixSize-1) || obj.invFinish
                obj.rowCountGJordan = cast(1, 'like', obj.rowCountGJordan);
            elseif obj.rowFinish && obj.rowCountGJordanReg ~= obj.MatrixSize
                obj.rowCountGJordan = obj.rowCountGJordanReg + 1;
            else
                obj.rowCountGJordan = obj.rowCountGJordanReg;
            end            
        end        
        
        function GaussJordanDataValidIn(obj)
            % diagValidIn will be enabled when rowCount equals to colCount
            % nonDiagValidIn will be enabled when rowCount not equals to
            % colCount
            obj.diagValidIn = obj.readEnableReg && obj.gaussJordanEnbReg && ~obj.swapEnabReg && (obj.rowCountGJordanReg == obj.colCountGJordanReg);           
            obj.nonDiagValidIn = obj.readEnableReg && obj.gaussJordanEnbReg && ~obj.swapEnabReg && (obj.rowCountGJordanReg ~= obj.colCountGJordanReg);               
        end
        
        %Swapping logic
        function SwappingLogic(obj)
            
            % swapEnab will be enabled whenever the diagonalValidIn is enabled before swapping 
            if obj.swapEnbFlag
                obj.swapEnab = true;
            elseif obj.swapDoneReg
                obj.swapEnab = false;
            else
                obj.swapEnab = obj.swapEnabReg;
            end
            

            % swapReadEnable will be enabled whenever the diagonalValidIn is enabled 
            if obj.swapEnbFlag
                obj.swapReadEnable = true;
            elseif obj.swapDoneReg
                obj.swapReadEnable = false;
            else
                obj.swapReadEnable = obj.swapReadEnableReg;    
            end
                       
            % swapDone is the flag which will be enabled after swapping two
            % rows
            if obj.swapEnabReg && obj.swapEnableOutReg && ~obj.swapDoneReg
                obj.swapDone = true;
            else
                obj.swapDone = false;
            end
            
            %Storing columnCountGJordanReg and readData when diagValidIn is
            %enabled
            if obj.swapEnbFlag
                obj.colCountStoreDiagZero = obj.colCountGJordanReg_1;
                obj.storedDiagZeroData    = obj.readData;
            else
                obj.colCountStoreDiagZero = obj.colCountStoreDiagZeroReg;
                obj.storedDiagZeroData    = obj.storedDiagZeroDataReg;
            end
            
            % Finding maximum element in the corresponding diagonal element
            % column
            if obj.diagValidInReg
                obj.maxColumnData      =  obj.readData;
                obj.maxColCountGJordan = obj.colCountGJordanReg_1;
            elseif abs(obj.readData(obj.rowCountGJordanReg)) > abs(obj.maxColumnDataReg(obj.rowCountGJordanReg))...
                   && (obj.colCountGJordanReg_1 > obj.rowCountGJordanReg) && obj.colCountGJordanReg_1 <=obj.MatrixSize && obj.swapReadEnableReg_1
                obj.maxColumnData      = obj.readData;
                obj.maxColCountGJordan = obj.colCountGJordanReg_1;
            else
                obj.maxColumnData      = obj.maxColumnDataReg;
                obj.maxColCountGJordan = obj.maxColCountGJordanReg;
            end
            
            % maxFinish will be enabled after completing maximum element
            if obj.colCountGJordanReg == obj.MatrixSize +1
                obj.maxFinish = true;
            else
                obj.maxFinish = false;
            end
            
            % swapEnableOut will be write enable for memories during
            % swapping process
            if obj.swapDoneReg
                obj.swapEnableOut = false;
            elseif obj.swapEnabReg && obj.maxFinishReg
                obj.swapEnableOut = true;
            else
                obj.swapEnableOut = obj.swapEnableOutReg;
            end
            % swapAddrOut will be write address during swapping process
            if obj.maxFinishReg_1
                obj.swapAddrOut = obj.maxColCountGJordanReg;
            elseif obj.maxFinishReg
                obj.swapAddrOut = obj.colCountStoreDiagZeroReg;
            else
                obj.swapAddrOut = obj.swapAddrOutReg;
            end
            
            % swapDataOut will be write data during swapping process
            if obj.maxFinishReg_1
                obj.swapDataOut = obj.storedDiagZeroDataReg;
            elseif obj.maxFinishReg
                obj.swapDataOut = obj.maxColumnDataReg;
            else
                obj.swapDataOut = obj.swapDataOutReg;
            end
            
            % Storing swapped data into memory
            if obj.swapEnableOutReg
               obj.matInvMemGaussJordan(:,obj.swapAddrOutReg) = obj.swapDataOutReg;
            end                   
        end    
        
        function DiagNonDiagProcessing(obj)
            
            obj.diagValidInReg_f_Reg  =  obj.diagValidInReg_f;
            
            obj.diagValidInReg_f_countReg_1 =  obj.diagValidInReg_f_countReg;
            obj.diagValidInReg_f_countReg = obj.diagValidInReg_f_count;
            
            obj.nonDiagValidInReg_f_Reg  =  obj.nonDiagValidInReg_f;
            
            obj.nonDiagValidInReg_f_countReg_1 = obj.nonDiagValidInReg_f_countReg;           
            obj.nonDiagValidInReg_f_countReg = obj.nonDiagValidInReg_f_count;              
            
            obj.colCountGJordanReg_f_Reg_1 = obj.colCountGJordanReg_f_Reg;
            obj.colCountGJordanReg_f_Reg = obj.colCountGJordanReg_f;            
            
            % diagValidInReg_f will be enabled during process of serial diagonal
            % elements computation
            if obj.diagValidInReg_f_countReg == obj.MatrixSize && obj.diagValidInReg_f
                obj.diagValidInReg_f = false;            
            elseif obj.diagValidInReg && obj.swapDoneReg_2
                obj.diagValidInReg_f = true;
            else
                obj.diagValidInReg_f = obj.diagValidInReg_f_Reg;
            end
            % diagonal element data is selected after swapping
            obj.diagDataReg = obj.diagData;
            if obj.diagValidInReg && obj.swapDoneReg_2
                obj.diagData = obj.readData(obj.rowCountGJordanReg);
            else
                obj.diagData = obj.diagDataReg;
            end
            
            % readData will be stored into readDataProcess when diagValidIn
            % or nonDiagValidIn enabled
            obj.readDataProcessReg = obj.readDataProcess;
            if obj.diagValidInReg || obj.nonDiagValidInReg
                obj.readDataProcess = obj.readData;
            else
                obj.readDataProcess = obj.readDataProcessReg;
            end    
            
            % First input selection for multiply or divide operation
            if obj.diagValidInReg_f_Reg
                obj.multiplyDivideInputOne = obj.diagDataReg;
            else
                obj.multiplyDivideInputOne = obj.readDataProcessReg(obj.rowCountGJordanReg);
            end    
            % Second input selection for multiply or divide operation based on the diagonal
            % processing enable or non-diagonal processing enable
            if obj.diagValidInReg_f_Reg
                obj.multiplyDivideInputTwo = obj.readDataProcessReg(obj.diagValidInReg_f_countReg);
                obj.multiplyDivideTwoEyeMem = obj.readDataProcessReg(obj.diagValidInReg_f_countReg + obj.MatrixSize);
            elseif obj.nonDiagValidInReg_f_Reg
                obj.multiplyDivideInputTwo = obj.diagStoredData(obj.nonDiagValidInReg_f_countReg);
                obj.multiplyDivideTwoEyeMem = obj.diagStoredExtraMem(obj.nonDiagValidInReg_f_countReg);
            else
                obj.multiplyDivideInputTwo    = cast(0 ,'like', obj.multiplyDivideInputTwo);
                obj.multiplyDivideTwoEyeMem = cast(0, 'like', obj.multiplyDivideTwoEyeMem);
            end
                           
            % First input selection for subtraction during non-diagonal
            % elements calculation
            obj.subtractFirstInputReg = obj.subtractFirstInput;
            obj.subtractFirstInputExtraMemReg = obj.subtractFirstInputExtraMem;
            obj.subtractFirstInput = obj.readDataProcessReg(obj.nonDiagValidInReg_f_countReg);
            obj.subtractFirstInputExtraMem = obj.readDataProcessReg(obj.nonDiagValidInReg_f_countReg+obj.MatrixSize);
            
            % Division will be done during diagonal processing enable is 'on'
            % Multiplication will be done during non diagonal processing
            % enable 'on'(A to I)
            obj.MultiplyDivideOutReg = obj.MultiplyDivideOut;
            if obj.diagValidInReg_f_Reg
                obj.MultiplyDivideOut = obj.multiplyDivideInputTwo / obj.multiplyDivideInputOne;
            else
                obj.MultiplyDivideOut = obj.multiplyDivideInputOne * obj.multiplyDivideInputTwo;
            end
                        
            % Similar operation Multiplication or Division will be done
            % for I to Ainv also
            obj.MutliplyDivideOutEyeMemReg = obj.MutliplyDivideOutEyeMem;
            if obj.diagValidInReg_f_Reg
                 obj.MutliplyDivideOutEyeMem = obj.multiplyDivideTwoEyeMem / obj.multiplyDivideInputOne;
            else    
                 obj.MutliplyDivideOutEyeMem = obj.multiplyDivideInputOne * obj.multiplyDivideTwoEyeMem;
            end
            
            % Subtraction will be done only for non-diagonal elements
            % calculation after multiplication
            % SubtractOut will be division output for diagonal elements
            % calculation or subtraction out for non-diagonal elements
            % calculation
            if obj.diagValidOutReg
                obj.subtractOut = obj.MultiplyDivideOutReg;
                obj.subtractOutEyeMem = obj.MutliplyDivideOutEyeMemReg;
            else
                obj.subtractOut = obj.subtractFirstInputReg - obj.MultiplyDivideOutReg;
                obj.subtractOutEyeMem = obj.subtractFirstInputExtraMemReg - obj.MutliplyDivideOutEyeMemReg; 
            end
            
            % colCount is storing into register when diagonalValidIn or
            % nonDiagonalValidIn enabled
            if obj.diagValidInReg || obj.nonDiagValidInReg
             obj.colCountGJordanReg_f = obj.colCountGJordanReg_1;
            else
             obj.colCountGJordanReg_f =  obj.colCountGJordanReg_f_Reg; 
            end
            
            
                
            % Storing subtractOut data into memory based on the enabling of
            % diagonalValidOut or nonDiagonalValidOut signals
            if obj.diagValidOutReg
               obj.matInvMemGaussJordan(obj.diagValidInReg_f_countReg_1, obj.colCountGJordanReg_f_Reg_1) = obj.subtractOut;
               obj.matInvMemGaussJordan(obj.diagValidInReg_f_countReg_1 + obj.MatrixSize, obj.colCountGJordanReg_f_Reg_1) =   obj.subtractOutEyeMem;       
            elseif obj.nonDiagValidOutReg
               obj.matInvMemGaussJordan(obj.nonDiagValidInReg_f_countReg_1, obj.colCountGJordanReg_f_Reg_1) = obj.subtractOut;
               obj.matInvMemGaussJordan(obj.nonDiagValidInReg_f_countReg_1 + obj.MatrixSize, obj.colCountGJordanReg_f_Reg_1) =   obj.subtractOutEyeMem;
            else
               obj.matInvMemGaussJordan = obj.matInvMemGaussJordan; 
               obj.matInvMemGaussJordan = obj.matInvMemGaussJordan;
            end    
            
            % Division output will be stored into registers during diagonal
            % elements calculation which will be used for non-diagonal elements calculation 
            if obj.diagValidInReg_f_Reg
                obj.diagStoredData(obj.diagValidInReg_f_countReg) = obj.MultiplyDivideOut;
            else
                obj.diagStoredData = obj.diagStoredData;
            end
            % Division output will be stored into registers during diagonal
            % elements calculation which will be used for non-diagonal
            % elements calculation of Eye memory
            if obj.diagValidInReg_f_Reg
                obj.diagStoredExtraMem(obj.diagValidInReg_f_countReg) = obj.MutliplyDivideOutEyeMem;
            else
                obj.diagStoredExtraMem = obj.diagStoredExtraMem;    
            end
                        
            % diagValidCount will be used to select the inputs for division
            % operation during diagonal elements calculation
            if obj.diagValidInReg_f_countReg == obj.MatrixSize && obj.diagValidInReg_f_Reg
                obj.diagValidInReg_f_count = cast(1, 'like', obj.diagValidInReg_f_count);            
            elseif obj.diagValidInReg_f_Reg
                obj.diagValidInReg_f_count = obj.diagValidInReg_f_countReg + 1;
            else
                obj.diagValidInReg_f_count = obj.diagValidInReg_f_countReg;
            end
            
            % nonDiagValid enable signal will be 'on' during non-diagonal
            % elements calculation
            if obj.nonDiagValidInReg 
                obj.nonDiagValidInReg_f = true;
            elseif obj.nonDiagValidInReg_f_countReg == obj.MatrixSize
                obj.nonDiagValidInReg_f = false;
            else
                obj.nonDiagValidInReg_f = obj.nonDiagValidInReg_f_Reg;
            end

            % nonDiagValid count will be used in selection inputs of multiplication 
            % subtraction during non-diagonal elements calculation
            if obj.nonDiagValidInReg_f_countReg == obj.MatrixSize && obj.nonDiagValidInReg_f_Reg
                obj.nonDiagValidInReg_f_count = cast(1, 'like', obj.nonDiagValidInReg_f_count);            
            elseif obj.nonDiagValidInReg_f_Reg
                obj.nonDiagValidInReg_f_count = obj.nonDiagValidInReg_f_countReg + 1;
            else
                obj.nonDiagValidInReg_f_count = obj.nonDiagValidInReg_f_countReg;
            end
            
            % diagValidOut signal will be enabled after completion of row
            % transformation of diagonal element
            obj.diagValidOut = obj.diagValidInReg_f_Reg;
              

            % nonDiagValidOut signal will be enabled after completion of
            % row transformation of non-diagonal element
            obj.nonDiagValidOut = obj.nonDiagValidInReg_f_Reg;            
            
            % nonDiagValidCount will be incremented with nonDiagValidOut
            % signal
            if obj.nonDiagValidOutCountReg == ((obj.MatrixSize*(obj.MatrixSize-1))-1) && obj.nonDiagValidOutReg
                obj.nonDiagValidOutCount = cast(0, 'like', obj.nonDiagValidOutCount);            
            elseif obj.nonDiagValidOutReg
                obj.nonDiagValidOutCount = obj.nonDiagValidOutCountReg + 1;

            else
                obj.nonDiagValidOutCount = obj.nonDiagValidOutCountReg;
            end  
           
           % Whenever the invFinish signal on outRdy signal will be enabled
           % for ZERO latency where as for MAX latency holdValid will be
           % enabled because pipeline delays will be added as lump delay at
           % output ports
           if obj.invFinish
               if strcmpi(obj.LatencyStrategyType, 'ZERO')
                   obj.outRdy          = cast(1,'like',obj.outRdy);
                   obj.invFinish       = cast(0, 'like', obj.invFinish);
                   if obj.MatrixSize == 1
                       obj.flagRdyLast     = cast(1 ,'like', obj.flagRdyLast);
                   end
               else
                   obj.holdValid       = cast(1, 'like', obj.holdValid);
                   obj.invFinish       = cast(0, 'like', obj.invFinish);
               end
           end
           
           % making storeDone flag to false after loading of matrix
           if obj.storeDone
               obj.storeDone      = false;
           end
            
        end
        
        % Streaming output matrix(Ainv) after processing is done
        function  OutputStreamingGJordan(obj,outEnb)
            if(obj.outRdy && outEnb)
                obj.dataOut   = cast(obj.matInvMemGaussJordan(obj.numCol+obj.MatrixSize,obj.numRow),'like',obj.matInvMemGaussJordan(obj.numRow+obj.MatrixSize,obj.numCol));
                obj.validOut  = cast(1,'like',obj.outRdy);
            else
                obj.dataOut   = cast(0 , 'like', obj.dataOut);
                obj.validOut  = cast(0,'like',obj.outRdy);
            end
        end                    
        
    end
end

% LocalWords:  Linv Ainv Enb Rdy pdata pvalid myproperty Lwr Buf Prev Datawd
% LocalWords:  MatrixSize Buf's matinv Symm gauss Vld Enab GJordan
