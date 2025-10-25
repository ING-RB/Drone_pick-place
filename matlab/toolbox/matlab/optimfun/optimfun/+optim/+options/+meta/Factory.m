classdef (Abstract) Factory
%

%Factory Static class used to create specific instances of 
%optim.options.meta.OptionType classes.
%
% optim.options.meta.Factory contains static function as shortcuts to
% create common specialized option types, as well as Constant
% pre-constructed instances of optim.options.meta.OptionsType for options
% that appear in multiple solvers (e.g. ConstraintTolerance). These
% constant types function effectively as singletons for the session.
%
% Static methods:
% ---------------
% onOffType
% fractionalType
% positiveRealType
% plotFcnType
% resourceLimitType
% algorithmType
% displayType
% toleranceType
% numericWithEmptyType
% numericType
% matrixStructType
% logicalWithEnumType
% logicalType
% integerType
% fileType
% fcnType
% enumWithCellType
% enumType
%
% constraintToleranceType
% functionToleranceType
% optimalityToleranceType
% stepToleranceType
% maxIterType
% maxFunEvalsType
% maxTimeType
% objectiveLimitType
% typicalXType
% outputFcnType
% hybridFcn
% useParallelType
% useVectorizedType
% specifyConstraintGradientType
% specifyObjectiveGradientType
% checkGradientsType
% hessianMultiplyFcnType
%

% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.ENUMTYPE

%   Copyright 2021-2022 The MathWorks, Inc.

    % NOTE: lower case method names. PRISM compliant!
    methods (Static)
        function dt = displayType(values)
            dt = optim.options.meta.EnumType(values,label('Display'),category('Diagnostic'));            
        end
        
        function at = algorithmType(values)
            at = optim.options.meta.EnumType(values,label('Algorithm'),category('Algorithm'));
        end
        
        function rlt = resourceLimitType(label)
            rlt = optim.options.meta.IntegerType([0 Inf],label,category('RunTime'));            
        end        
        
        function pt = plotFcnType(values)
            pt = optim.options.meta.FcnWithCellType(label('PlotFcn'),category('Diagnostic'),values);
        end
        
        function prt = positiveRealType(label,category)
            prt = optim.options.meta.NumericType('scalar',[0 Inf],[false true],label,category);
        end
        
        function ft = fractionalType(label,category)
            ft = optim.options.meta.NumericType('scalar',[0 1],[true true],label,category);            
        end
        
        function oot = onOffType(label,category)
            % NOTE: most examples of this are hidden, so by default we have
            % no label because no GUI for these. However, MATLAB solvers
            % will use these and they will require a label.
            if nargin < 1
                label = ''; 
                category = '';
            end
            oot = optim.options.meta.EnumType({'on','off'},label,category);
        end

        % Pure factory methods (simple wrapped constructor calls)
        % These are so that all creation methods for option meta types is
        % contained here.
        
        function et = enumType(values,label,category)
            et = optim.options.meta.EnumType(values,label,category);
        end
        
        function ect = enumWithCellType(values,othertype,idx,label,category,varargin)
            ect = optim.options.meta.EnumWithCellType(values,othertype,idx,label,category,varargin{:});
        end
        
        function ft = fcnType(label,category,varargin)
            ft = optim.options.meta.FcnType(label,category,varargin{:});
        end
        
        function fct = fcnWithCellType(label,category,varargin)
            fct = optim.options.meta.FcnWithCellType(label,category,varargin{:});
        end        
        
        function ft = fileType(fileExt,label,category)
            ft = optim.options.meta.FileType(fileExt,label,category);
        end
        
        function it = integerType(limits,label,category)
            it = optim.options.meta.IntegerType(limits,label,category);
        end
        
        function lt = logicalType(label,category)
            lt = optim.options.meta.LogicalType(label,category);
        end
        
        function let = logicalWithEnumType(label,category,values)
            let = optim.options.meta.LogicalWithEnumType(label,category,values);
        end
        
        function let = logicalWithHiddenStringType(label,category,values)
            let = optim.options.meta.LogicalWithHiddenStringType(label,category,values);
        end
        
        function mst = matrixStructType(label,category)
            mst = optim.options.meta.MatrixStructType(label,category);
        end        
        
        function nt = numericType(shp,limits,inclusive,label,category)
            nt = optim.options.meta.NumericType(shp,limits,inclusive,label,category);
        end
        
        function net = numericWithEmptyType(shp,limits,inclusive,label,category)
            net = optim.options.meta.NumericWithEmptyType(shp,limits,inclusive,label,category);
        end
        
        function tt = toleranceType(label)
            tt = optim.options.meta.ToleranceType(label);
        end
        
        function ssrt = sameSignRangeType(limits,inclusive,label,category)
            ssrt = optim.options.meta.SameSignRangeType(limits,inclusive,label,category);
        end

        % Convenience static methods for certain options

        % Tolerances
		function ct = constraintToleranceType
            ct = optim.options.meta.ToleranceType(label('TolCon'));
		end
	
        function ct = functionToleranceType
            ct = optim.options.meta.ToleranceType(label('TolFun'));
		end
         
        function ct = optimalityToleranceType
            ct = optim.options.meta.ToleranceType(label('TolOpt'));
		end

        function ct = stepToleranceType
            ct = optim.options.meta.ToleranceType(label('TolX'));
		end

        % Resources
        function ct = maxIterType
            ct = optim.options.meta.Factory.resourceLimitType(label('MaxIter'));
        end

        function ct = maxFunEvalsType
            ct = optim.options.meta.Factory.resourceLimitType(label('MaxFunEvals'));
        end

        % Numerics
        function ct = maxTimeType
            ct = optim.options.meta.NumericType('scalar',[0 Inf], ...
                [true true],label('MaxTime'),category('RunTime'));
        end
        
        function ct = objectiveLimitType
            ct = optim.options.meta.NumericType('scalar',[-Inf,Inf],...
                [true false],label('ObjLimit'),category('Tolerances'));
        end

        function ct = typicalXType
            ct = optim.options.meta.ExcludeZeroType('matrix',[-Inf Inf], ...
                [false false],label('TypicalX'),category('Derivatives'));
        end
        
        % Functions
        function ct = outputFcnType
            ct = optim.options.meta.FcnWithCellType(label('OutputFcn'),category('Diagnostic'),{});
        end

        function fct = hybridFcn(solvers)
            fct = optim.options.meta.HybridFcn(solvers);
        end 

        % Logicals
        function ct = useParallelType
            ct = optim.options.meta.LogicalWithEnumType(label('UseParallel'), ...
                category('Derivatives'),{'always','never'});        
        end

        function ct = useVectorizedType
            ct = optim.options.meta.LogicalType(label('Vectorized'),category('Algorithm'));        
        end

        function ct = specifyConstraintGradientType
            ct = optim.options.meta.LogicalType(label('GradConstr'),category('Derivatives'));
        end

        function ct = specifyObjectiveGradientType
            ct = optim.options.meta.LogicalType(label('GradObj'),category('Derivatives'));
        end

        function ct = checkGradientsType
            ct = optim.options.meta.LogicalType(label('CheckGrad'),category('Derivatives'));
        end

        % Derivatives 
        function ct = finiteDifferenceStepSizeType 
            ct = optim.options.meta.NumericType('vector',[0 Inf],[false true],label('FinDiffStep'),category('Derivatives'));
        end
        
        function ct = finiteDifferenceType 
            ct = optim.options.meta.EnumType({'forward','central'},label('FinDiffType'),category('Derivatives'));
        end
        
        function ct = hessianMultiplyFcnType 
            ct = optim.options.meta.FcnType(label('HessMult'),category('Derivatives'));
        end
    end
end

%--------------------------------------------------------------------------
% Helper functions for retrieving catalog entries
function c = category(key)
    c = optim.options.meta.category(key);
end

function lbl = label(key)
    lbl = optim.options.meta.label(key);
end
