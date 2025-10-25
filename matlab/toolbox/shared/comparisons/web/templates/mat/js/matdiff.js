/*
 * matdiff.js
 * Javascript functions to support operations in MAT-file comparison reports
 *
 * Getting the root window is browser dependent.  On some platforms the
 * parent of root is the window, and window.window is window.
 * On other browsers, parent can be undefined.
 *
 * Copyright 2010-2022 The MathWorks, Inc.
 */

/* eslint-disable no-undef */
/* eslint-disable camelcase */
/* eslint-disable no-unused-vars */

function getRootWindow () {
    if (parent) {
        return parent.window;
    } else {
        return window;
    }
}

async function comparisons_private (args, onSuccess = () => {}) {
    const rootWindow = getRootWindow();
    if (typeof rootWindow.runMATLABFeval === 'function') {
        rootWindow.runMATLABFeval('comparisons_private', args, onSuccess);
    } else {
        rootWindow.MATLAB.feval('comparisons_private', args, 0);
    }
}

async function MATLABEval (cmd) {
    const rootWindow = getRootWindow();
    if (typeof rootWindow.runMATLABEval === 'function') {
        rootWindow.runMATLABEval('evalin("base", "' + cmd + '")');
    } else {
        rootWindow.MATLAB.eval(cmd);
    }
}

async function openvar (side, varname) {
    if (side === 'left') {
        comparisons_private([ 'matview', LEFT_FILE, varname, '_left' ]);
    } else {
        comparisons_private([ 'matview', RIGHT_FILE, varname, '_right' ]);
    }
}

async function mergeleft (varname) {
    const onSuccess = async () => { await refreshReportIfNoJava(); };
    await comparisons_private(
        [ 'varmerge', RIGHT_FILE, LEFT_FILE, varname, REPORT_ID ], onSuccess);
}

async function mergeright (varname) {
    const onSuccess = async () => { await refreshReportIfNoJava(); };
    await comparisons_private(
        [ 'varmerge', LEFT_FILE, RIGHT_FILE, varname, REPORT_ID ], onSuccess);
}

async function comparevar (varname) {
    comparisons_private([ 'varcomp', LEFT_FILE, RIGHT_FILE, varname ]);
}

async function refreshReportIfNoJava () {
    const rootWindow = getRootWindow();
    if (typeof rootWindow.refreshMatDiffReport === 'function') {
        await rootWindow.refreshMatDiffReport();
    }
}
