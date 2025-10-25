from _ast import BoolOp, UnaryOp
import ast
from typing import Any

def getIOTypes(fname : str) -> list:
    with open(fname,'r') as file:
        data = open(fname,'r').read()
        file.close()

        rtnList = []
        tree = ast.parse(data)        
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                defName = node.name
                funcsig = { 'defName' : '', 'input' : [], 'output' : [] }
                funcsig['defName'] = defName
                funcsig['input'] = getInputArgs(node)
                funcsig['output'] = getReturnArgs(node)
                rtnList.append(funcsig)
        return rtnList

def getReturnArgs(node) -> list:
    rtnList = []
    nodeArg = node.returns

    for node1 in ast.walk(node):
        if isinstance(node1, ast.Return):
            for field, value in ast.iter_fields(node1):
                numel = 1
                rtnType = ''
                tup = tuple()
                labelList = []

                if isinstance(value, ast.List) or isinstance(value, ast.Tuple) :
                    for item in value.elts:                        
                        if isinstance(item, ast.Name):
                            labelList.append(item.id)
                        else:
                            labelList.append('')
                    numel = len(value.elts)
                    rtnType = type(value)
                    tup = (labelList, rtnType, numel)
                elif isinstance(value, ast.Dict):
                    for item in value.keys:
                        labelList.append(item.s)
                    numel = len(value.keys)
                    rtnType = type(value)
                    tup = (labelList, rtnType, numel)
                else:
                    numel = 1
                    if isinstance(nodeArg, ast.Name):
                        rtnType = nodeArg.id
                        if isinstance(value, ast.Name):
                            labelList = value.id
                    elif isinstance(nodeArg, ast.Attribute):
                        for field, value in ast.iter_fields(nodeArg):
                            rtnType = value.id + '.' + nodeArg.attr
                            break
                    else:
                        if isinstance(value, ast.Name):
                            labelList = value.id
                        elif value == None:                            
                            numel = 0
                    tup = (labelList, rtnType, numel)
                rtnList.append(tup)

    return rtnList

def getInputArgs(node) -> list:
    rtnList = []
    nodeArgs = node.args
    nargs = nodeArgs.args
    for narg in nargs:
        #breakpoint()
        annotationStr = ''
        narg_name = narg.arg
        narg_annotation = narg.annotation
        if isinstance(narg_annotation, ast.Name):
            annotationStr = narg_annotation.id
        elif isinstance(narg_annotation, ast.Str):
            annotationStr = narg_annotation.s
        elif isinstance(narg_annotation, ast.Attribute):
            for field, value in ast.iter_fields(narg_annotation):
                annotationStr = value.id + '.' + narg_annotation.attr
                break
        inarg = (narg_name, annotationStr)
        rtnList.append(inarg)
    return rtnList

def getImports(fname : str) -> list:
    rtnList = []
    with open(fname,'r') as file:
        data = open(fname,'r').read()
        file.close()
        tree = ast.parse(data)
        res = {}
        for node in ast.walk(tree):
            #breakpoint()
            if isinstance(node, ast.Import):
                importName = node.names[0].name
                rtnList.append(importName)
            elif isinstance(node, ast.ImportFrom):
                nodeList = node.names
                importName = node.module
                rtnList.append(importName)
            else:
                continue
        return rtnList

def getImportsFromInitFile(fname : str) -> list:
    rtnList = []
    with open(fname,'r') as file:
        data = open(fname,'r').read()
        file.close()
        tree = ast.parse(data)
        res = {}
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign):
                if node.targets[0].id == '__all__':
                    numel = len(node.value.elts)
                    for item in node.value.elts:
                        rtnList.append(item.value)
                else:
                    continue

            elif isinstance(node, ast.ImportFrom):
                modName = node.module
                for item in node.names:
                    rtnList.append(modName+ '.' + item.name)

            elif isinstance(node, ast.Module):
                if isinstance(node.body[0], ast.Import):
                    for item in node.body[0].names:
                        rtnList.append(item.name)

            else:
                continue
        return rtnList        

def getVars(code : str) -> dict:
    """ getVars takes Python code as input and returns
        a dictionary with the following info:

        key                | value
        -------------------------------------------------------------------------
        mlvars             | a list of undefined variable names used in assignment
                           | at the global scope wrt. to the code string.
        -------------------------------------------------------------------------
        pyvars             | a list of python variables that will be generated
                           | during the execution on the code string. The set
                           | will only contain global scope vars wrt. to the code
        -------------------------------------------------------------------------
        exception          | a tuple containing the Python exception obj, id and msg
                           | if the code parsing generates one, otherwise None
        -------------------------------------------------------------------------
        ast_head           | head node for the ast object
        -------------------------------------------------------------------------
    """
    res = { 'mlvars' : list(), 'pyvars' : list(), 'exception' : None, 'ast_head' : None }

    try:
        head = ast.parse(code)
        res['ast_head'] = head

        class Visitor(ast.NodeVisitor):
            # no-op operations : list, set and dict comprehensions as well as generator expressions: 
            def visit_ListComp(self, node):
                pass

            def visit_SetComp(self, node):
                pass

            def visit_DictComp(self, node):
                pass

            def visit_GeneratorExp(self, node):
                pass

            # Bool operation visitor
            def visit_BoolOp(self, node):
                for value in node.values:
                    if isinstance(value, ast.Name) and value.id not in res['pyvars'] and value.id not in res['mlvars']:
                        res['mlvars'].append(value.id)
                self.generic_visit(node)

            # Function call visitor
            def visit_Call(self, node):
                for arg in node.args:
                    if isinstance(arg, ast.Name) and arg.id not in res['pyvars'] and arg.id not in res['mlvars']:
                        res['mlvars'].append(arg.id)
                self.generic_visit(node)

            # Binary operation visitor
            def visit_BinOp(self, node):
                for child in [node.left, node.right]:
                    if isinstance(child, ast.Name) and child.id not in res['pyvars'] and child.id not in res['mlvars']:
                        res['mlvars'].append(child.id)
                self.generic_visit(node)

            # Unary operation visitor
            def visit_UnaryOp(self, node):
                if isinstance(node.operand, ast.Name) and node.operand.id not in res['pyvars'] and node.operand.id not in res['mlvars']:
                    res['mlvars'].append(node.operand.id)
                self.generic_visit(node)


        for node in head.body:
            # Assignment node
            if isinstance(node, ast.Assign):
                """
                ast.Assign may be one of the following forms:

                assignment statement      | targets                | value
                ------------------------------------------------------------------------
                a = 3                     | [ast.Name]             | ast.Num
                a = b                     | [ast.Name]             | ast.Name
                a, b = c, 42              | [ast.Tuple]            | ast.Tuple
                [a, b] = c, 42
                [a, b] = (c, 42)
                a, b = (c, 42)
                """
                lhs = node.targets
                for name in lhs:
                    if isinstance(name, ast.Tuple) or isinstance(name, ast.List):
                        for tn in name.elts:
                            if tn.id not in res['pyvars']:
                                res['pyvars'].append(tn.id)
                    else:
                        if name.id not in res['pyvars']:
                            res['pyvars'].append(name.id)

                rhs = node.value
                if isinstance(rhs, ast.Tuple) or isinstance(rhs, ast.List):
                    for tn in rhs.elts:
                        if isinstance(tn, ast.Name):
                            if tn.id not in res['pyvars']:
                                res['mlvars'].append(tn.id)
                elif isinstance(rhs, ast.Name) and rhs.id not in res['pyvars'] and rhs.id not in res['mlvars']:
                    res['mlvars'].append(rhs.id)
                else:
                    Visitor().visit(rhs)

            # Expressions with no assignment statement.
            elif isinstance(node, ast.Expr):
                Visitor().visit(node)

    except Exception as e:
        res['exception'] = str(e)

    return res