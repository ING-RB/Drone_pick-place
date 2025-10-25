/*
 * getPublishableReport.js
 * Defines utility functions to create a static printable version of the report.
 *
 * Copyright 2021-2022 The MathWorks, Inc.
 */

/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
'use strict';

function getPublishableReport (reportRoot) {
    const elementsToRemove =
        ['#leftText', '#rightText', 'script', 'iframe', '#MessageServiceManager'];
    const attributesToRemove = ['onload', 'onclick', 'href'];
    const classesToRemove = ['action', 'merge', 'compare', 'selected'];
    const headItemsToClone = ['meta', 'title', 'style[type*="text/css"]'];
    const deepClone = (elem) => elem.cloneNode(true);

    // Reconstruct the new body
    const newBody = deepClone(reportRoot.body);

    elementsToRemove.forEach((element) => {
        newBody.querySelectorAll(element).forEach(elem => elem.remove());
    });
    attributesToRemove.forEach((attribute) => {
        newBody.querySelectorAll('*[' + attribute + ']').forEach(elem => elem.removeAttribute(attribute));
    });
    classesToRemove.forEach((clazz) => {
        newBody.querySelectorAll('.' + clazz).forEach(elem => elem.classList.remove(clazz));
    });
    newBody.querySelectorAll('img').forEach(elem => { elem.src = toBase64DataURL(elem); });

    // Reconstruct the new head
    const newHead = document.createElement('head');
    headItemsToClone.forEach(item => {
        reportRoot.querySelectorAll(item).forEach(elem => {
            newHead.append(deepClone(elem));
        });
    });

    // Reconstruct the new tree
    const newDoc = document.createElement('html');
    newDoc.append(newHead);
    newDoc.append(newBody);

    return '<!DOCTYPE html>' + newDoc.outerHTML;
}

function toBase64DataURL (img) {
    // Create an empty canvas element
    const canvas = document.createElement('canvas');
    canvas.width = img.width;
    canvas.height = img.height;

    // Copy the image contents to the canvas
    const context = canvas.getContext('2d');
    context.drawImage(img, 0, 0);

    // Get the data-URL formatted image
    return canvas.toDataURL('image/png');
}
