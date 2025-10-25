////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////DATA////////////////////////////////////////

class DataWrapper {
  constructor(hc) {
    this.hc_ = hc; // htmlComponent
  }
  numAccordions() {
    var ad = this.hc_.Data.AccordionData;
    if (Array.isArray(ad)) {
      return ad.length;
    } else {
      return 1;
    }
  }
  getAccordionData(aidx) {
    var gd = this.hc_.Data.AccordionData;
    if (this.numAccordions() === 1) {
      return gd;
    } else {
      return gd[aidx];
    }
  }
  setAccordionData(aidx, gd) {
    if (this.numAccordions() === 1) {
      this.hc_.Data.AccordionData = gd;
    } else {
      this.hc_.Data.AccordionData[aidx] = gd;
    }
  }
  numRowsAtAccordion(aidx) {
    return this.getAccordionData(aidx).RowData.length;
  }
  numRows() {
    var sum = 0;
    for (var aidx = 0; aidx < this.numAccordions(); aidx++) {
      sum += this.numRowsAtAccordion(aidx);
    }
    return sum;
  }
  numVisibleRows() {
    var sum = 0;
    for (var aidx = 0; aidx < this.numAccordions(); aidx++) {
      if (this.getIsAccordionVisible(aidx)) {
        sum += this.numRowsAtAccordion(aidx);
      }
    }
    return sum;
  }
  numCols() {
    return this.getHeaderNames().length;
  }
  getNoContentMsg() {
    return this.hc_.Data.NoContentMsg;
  }
  getHeaderNames() {
    return this.hc_.Data.HeaderNames;
  }
  getRenderTypes() {
    return this.hc_.Data.RenderTypes;
  }
  getColAlign() {
    return this.hc_.Data.ColAlign;
  }
  getColWidth() {
    return this.hc_.Data.ColWidth;
  }
  getValueAt(aidx, ridx, cidx) {
    return this.getAccordionData(aidx).RowData[ridx][cidx];
  }
  getEditableAt(aidx, ridx, cidx) {
    if (this.numRowsAtAccordion(aidx) > 1) {
      return Boolean(this.getAccordionData(aidx).Editable[ridx][cidx]);
    } else {
      return Boolean(this.getAccordionData(aidx).Editable[cidx]);
    }
  }
  setEditableAt(aidx, ridx, cidx, val) {
    var gd = this.getAccordionData(aidx);
    if (this.numRowsAtAccordion(aidx) > 1) {
      gd.Editable[ridx][cidx] = val;
    } else {
      gd.Editable[cidx] = val;
    }
    this.setAccordionData(aidx, gd);
  }
  getEnabledAt(aidx, ridx, cidx) {
    if (this.numRowsAtAccordion(aidx) > 1) {
      return Boolean(this.getAccordionData(aidx).Enabled[ridx][cidx]);
    } else {
      return Boolean(this.getAccordionData(aidx).Enabled[cidx]);
    }
  }
  setEnabledAt(aidx, ridx, cidx, val) {
    var gd = this.getAccordionData(aidx);
    if (this.numRowsAtAccordion(aidx) > 1) {
      gd.Enabled[ridx][cidx] = val;
    } else {
      gd.Enabled[cidx] = val;
    }
    this.setAccordionData(aidx, gd);
  }
  getBGColorAt(aidx, ridx, cidx) {
    return this.getAccordionData(aidx).BackgroundColor[ridx][cidx];
  }
  getBGColorSemanticVarAt(aidx, ridx, cidx) {
    if (this.numRowsAtAccordion(aidx) > 1) {
      return this.getAccordionData(aidx).BackgroundColorSemanticVariable[ridx][cidx];
    } else {
      return this.getAccordionData(aidx).BackgroundColorSemanticVariable[cidx];
    }
  }
  getAccordionTitle(aidx) {
    return this.getAccordionData(aidx).AccordionTitle;
  }
  getRenderTitleAsHyperlink(aidx) {
    return this.getAccordionData(aidx).RenderTitleAsHyperlink;
  }
  getIsAccordionVisible(aidx) {
    return this.getAccordionData(aidx).IsAccordionVisible;
  }
  getIsAccordionCollapsed(aidx) {
    return this.getAccordionData(aidx).IsAccordionCollapsed;
  }

  getQEHTMLData() {
    var qedata;
    if (this.hc_.Data.hasOwnProperty("QEHTMLData")) {
      if (this.hc_.Data.QEHTMLData.hasOwnProperty("Type")) {
        qedata = this.hc_.Data.QEHTMLData;
      }
    }
    return qedata;
  }
  setHTMLIsBuilt() {
    var data_ = this.hc_.Data;
    data_.HTMLIsBuilt = true;
    this.hc_.Data = data_;
  }

  // EVENTS
  setValueAt(aidx, ridx, cidx, val) {

    var pre = this.getAccordionData(aidx).RowData[ridx][cidx];
    var data_ = this.hc_.Data;

    data_.JSEventData = {
      Type: "CellEdit",
      Data: {
        AccordIdx: aidx + 1,
        RowIdx: ridx + 1,
        ColIdx: cidx + 1,
        Value: val,
        OldValue: pre
      }
    };
    this.hc_.Data = data_;
  }
  setHeaderVal(cidx, val) {

    var data_ = this.hc_.Data;

    data_.JSEventData = {
      Type: "HeaderChange",
      Data: {
        ColIdx: cidx + 1,
        Value: val
      }
    };
    this.hc_.Data = data_;
  }
  setAccordionHyperlinkClicked(aidx) {
    var data_ = this.hc_.Data;
    data_.JSEventData = {
      Type: "AccordionHyper",
      Data: {
        AccordIdx: aidx + 1
      }
    };
    this.hc_.Data = data_;
  }
  setCellClickedAt(aidx, ridx, cidx) {
    var data_ = this.hc_.Data;
    data_.JSEventData = {
      Type: "CellClicked",
      Data: {
        AccordIdx: aidx + 1,
        RowIdx: ridx + 1,
        ColIdx: cidx + 1
      }
    };
    this.hc_.Data = data_;
  }
  setAccordionClickedAt(aidx) {
    var data_ = this.hc_.Data;
    data_.JSEventData = {
      Type: "AccordionClicked",
      Data: {
        AccordIdx: aidx + 1
      }
    };
    this.hc_.Data = data_;
  }
  notifyAccordionCollapsed(aidx, val) {
    var data_ = this.hc_.Data;
    data_.JSEventData = {
      Type: "AccordionCollapsed",
      Data: {
        AccordIdx: aidx + 1,
        Collapsed: val
      }
    };
    this.hc_.Data = data_;
  }
}

////////////////////////////////////////////////////////////////////////////////
//////////////////////////////INPUT HANDLERS////////////////////////////////////
function handleNumeric(val) {
  // handle numeric inputs.
  var out = Number(val);
  return out;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////HELPERS/////////////////////////////////////

function expandAccord(el, accord) {
  el.style.display = "table-row-group";
  accord.innerHTML = '&#9660;';
}
function collapseAccord(el, accord) {
  el.style.display = "none";
  accord.innerHTML = '&#9658;';
}

function toggleDisplay(dw, aidx, el, accord) {
  var val;
  if (el.style.display === "none") {
    expandAccord(el, accord);
    val = false;
  } else {
    collapseAccord(el, accord);
    val = true;
  }
  dw.notifyAccordionCollapsed(aidx, val);
}

function mapViz_(val) {
  var want;
  if (val) {
    want = "table-row-group";
  } else {
    want = "none";
  }
  return want;
}

function updateAccordionVisibility(dw, aidx) {
  // update the accordions for collapse

  var ge = getAccordionElements(aidx);
  var headerbody = ge.HeaderTbody;
  var tablebody = ge.TableTbody;
  var accord = ge.AccordButton;

  var wants_collapse = dw.getIsAccordionCollapsed(aidx);
  var wants_viz = dw.getIsAccordionVisible(aidx);
  var is_collapse = tablebody.style.display === "none";
  var is_viz = !(headerbody.style.display === "none");

  if (wants_viz !== is_viz) {
    headerbody.style.display = mapViz_(wants_viz);
    tablebody.style.display = mapViz_(wants_viz && !wants_collapse);
  }

  // only update collapse if visible
  if (wants_viz) {
    if (wants_collapse && !is_collapse) {
      collapseAccord(tablebody, accord);
    } else if (!wants_collapse && is_collapse) {
      expandAccord(tablebody, accord);
    }
  }
}

function textCellChangedCB(dw, event, aidx, rIdx, cIdx) {
  var val = event.srcElement.value;
  dw.setValueAt(aidx, rIdx, cIdx, val);
}

function numericCellChangedCB(dw, event, aidx, rIdx, cIdx) {
  var val = handleNumeric(event.srcElement.value);
  dw.setValueAt(aidx, rIdx, cIdx, Number(val));
}

function checkCellChangedCB(dw, event, aidx, rIdx, cIdx) {
  var val = event.srcElement.checked;
  dw.setValueAt(aidx, rIdx, cIdx, val);
  updateHeaderCheckboxState(dw, cIdx);
}

function updateHeaderCheckboxState(dw, cIdx) {
  var headerinput = document.getElementById("headerinput_" + cIdx.toString());

  if (headerinput) {
    var sum = 0;
    for (var aidx = 0; aidx < dw.numAccordions(); aidx++) {
      if (dw.getIsAccordionVisible(aidx)) {
        for (var rIdx = 0; rIdx < dw.numRowsAtAccordion(aidx); rIdx++) {
          var cell = getAccordionCell(aidx, rIdx, cIdx);
          var input = cell.children[0];
          sum += input.checked;
        }
      }
    }
    if (sum === 0) {
      headerinput.checked = false;
      headerinput.indeterminate = false;
    } else if (sum === dw.numVisibleRows()) {
      headerinput.checked = true;
      headerinput.indeterminate = false;
    } else {
      headerinput.checked = false;
      headerinput.indeterminate = true;
    }
  }
}

function updateAllHeaderCheckboxStates(dw) {
  for (var cIdx = 0; cIdx < dw.numCols(); cIdx++) {
    updateHeaderCheckboxState(dw, cIdx);
  }
}

function checkCellHeaderChangedCB(dw, event, cIdx) {
  // console.log(event.target.checked)
  var ischecked = event.srcElement.checked;
  dw.setHeaderVal(cIdx, ischecked);
}

function getAccordionElements(aidx) {
  var g1 = 2 * aidx;
  var g2 = g1 + 1;

  var tbodies = document.getElementsByTagName("tbody");
  var t1 = tbodies[g1];
  var t2 = tbodies[g2];

  var accord_btn = document.getElementById("accordbutton_" + aidx.toString());

  return {
    HeaderTbody: t1,
    TableTbody: t2,
    AccordButton: accord_btn
  };
}

function getAccordionCell(aidx, rIdx, cIdx) {
  var ge = getAccordionElements(aidx);
  var tbody_rows = ge.TableTbody;
  var tr = tbody_rows.children[rIdx];
  var td = tr.children[cIdx];
  return td;
}

function getAccordionCellInput(aidx, rIdx, cIdx) {
  var td = getAccordionCell(aidx, rIdx, cIdx);
  var input = td.children[0];
  return input;
}

function getInputByIndex(aidx, rIdx, cIdx) {
  var prefix = "input";
  var suffix = "_" + aidx.toString() + "_" + rIdx.toString() + "_" + cIdx.toString();
  var name = prefix + suffix;
  return document.getElementById(name);
}

function getCellByIndex(aidx, rIdx, cIdx) {
  var prefix = "cell";
  var suffix = "_" + aidx.toString() + "_" + rIdx.toString() + "_" + cIdx.toString();
  var name = prefix + suffix;
  return document.getElementById(name);
}

function createResizeDiv(isleft) {
  var div = document.createElement("div");
  if (isleft) {
    div.className = "colresizeleft";
  } else {
    div.className = "colresizeright";
  }
  return div;
}

function attachResizeDiv(parent, row, isleft) {

  var div = createResizeDiv(isleft);
  div.style.height = row.offsetHeight + "px";
  parent.appendChild(div);
  parent.style.position = "relative";

  // add the col resize listeners
  addColResizeListeners(div, row, isleft);
}

function addColResizeListeners(div, row, isleft) {
  // variables to manage event "state"
  var mouseDownPageX, currentCol, nextCol, currentColWidth, nextColWidth;

  // mousedown on div
  div.addEventListener("mousedown", function (event) {

    if (isleft) {
      nextCol = event.target.parentElement;
      currentCol = nextCol.previousElementSibling;
    } else {
      currentCol = event.target.parentElement;
      nextCol = currentCol.nextElementSibling;
    }
    mouseDownPageX = event.pageX;
    // currentColWidth = currentCol.offsetWidth;
    // nextColWidth    = nextCol.offsetWidth;
    currentColWidth = currentCol.clientWidth;
    nextColWidth = nextCol.clientWidth;
  });

  // mouse drag
  document.addEventListener("mousemove", function (event) {
    if (currentCol) {
      var d = event.pageX - mouseDownPageX;
      if (nextCol) {

        // min width of the cols
        var MINWIDTH = 10;
        d = Math.min(d, nextColWidth - MINWIDTH);
        d = Math.max(d, -currentColWidth + MINWIDTH);

        // set width based on deflection
        nextCol.style.width = parseInt(nextColWidth - d) + "px";
        currentCol.style.width = parseInt(currentColWidth + d) + "px";
      }
    }
  });

  // mouse up (release)
  document.addEventListener("mouseup", function (event) {
    // clear the callback "state"
    mouseDownPageX = undefined;
    currentCol = undefined;
    nextCol = undefined;
    currentColWidth = undefined;
    nextColWidth = undefined;
  })

}

function getColorString(c) {
  return "rgba(" + c[0].toString() +
    "," + c[1].toString() +
    "," + c[2].toString() +
    "," + c[3].toString() + ")";
}

function setElementBackgroundColor(el, c) {
  let color_var = "var(--mw-backgroundColor-input)";
  if (c !== undefined && c.length) {
    color_var = "var(" + c + ")";
  }
  el.style.backgroundColor = color_var;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////BUILD UI////////////////////////////////////

function createResizeCols(table) {
  var row = table.getElementsByTagName('tr')[0];
  var cols = row.children;

  for (var i = 0; i < cols.length; i++) {
    if (i < cols.length - 1) {
      // add a div to the right side of the th
      attachResizeDiv(cols[i], row, 0);
    }
    if (i > 0) {
      // add a div to the left side of the th
      attachResizeDiv(cols[i], row, 1);
    }
  }
}

function buildHeader(table, dw) {
  // build the headers and configure the initial column width

  var headerNames = dw.getHeaderNames();
  var colwidths = dw.getColWidth();
  var colalign = dw.getColAlign();
  var renderTypes = dw.getRenderTypes();
  var header = table.createTHead();
  var row = header.insertRow();

  for (var colIdx = 0; colIdx < headerNames.length; colIdx++) {
    var renderType = renderTypes[colIdx];
    var cell = document.createElement("th");
    cell.style.textAlign = colalign[colIdx];
    row.appendChild(cell);

    var label = document.createElement("label");
    label.appendChild(document.createTextNode(headerNames[colIdx]));
    label.title = headerNames[colIdx];

    if (renderType === "bool") {
      var input = document.createElement("input");
      input.id = "headerinput_" + colIdx.toString();
      input.type = "checkbox";
      input.checked = false;
      // input.intermediate = true;
      label.htmlFor = input.id;
      cell.appendChild(input);

      // attach a callback to the checkbox. see https://www.pluralsight.com/guides/javascript-callbacks-variable-scope-problem
      // for more info on the cb structure, due to async nature of js callbacks
      input.addEventListener("change", (function () {
        var cIdx = colIdx;
        return function (event) {
          checkCellHeaderChangedCB(dw, event, cIdx);
        };
      })());

    } else {
    }
    cell.appendChild(label);
    cell.style.width = colwidths[colIdx];
  }
}

function buildAccordions(table, dw) {

  // build the accordions
  var renderTypes = dw.getRenderTypes();
  var colAlign = dw.getColAlign();

  for (var accordIdx = 0; accordIdx < dw.numAccordions(); accordIdx++) {

    // create the accordion row
    var accord_tbody = document.createElement("tbody");
    var accord_tr = document.createElement("tr");
    table.appendChild(accord_tbody);
    accord_tbody.appendChild(accord_tr);
    var accord_td = accord_tr.insertCell(0);

    accord_td.className = "accordion";
    accord_td.colSpan = dw.numCols().toString();
    accord_td.id = "accordcell_" + accordIdx.toString();

    // add a click event listener on the cell
    accord_td.addEventListener("click", (function () {
      var a = accordIdx;
      return function (event) {
        dw.setAccordionClickedAt(a);
      };
    })());

    var accord_btn = document.createElement("button");
    accord_btn.className = "accordian";
    accord_btn.innerHTML = '&#9660;';
    accord_btn.id = "accordbutton_" + accordIdx.toString();

    var accord_hyper = document.createElement("a");
    accord_hyper.id = "accordhyper_" + accordIdx.toString();
    accord_hyper.innerHTML = dw.getAccordionTitle(accordIdx);
    accord_hyper.className = "accordiontext";
    accord_hyper.title = accord_hyper.innerHTML;

    // render the accordion as a hyperlink
    if (dw.getRenderTitleAsHyperlink(accordIdx)) {
      accord_hyper.href = "#";
      accord_hyper.addEventListener("click", (function () {
        var aidx = accordIdx;
        return function (event) {
          dw.setAccordionHyperlinkClicked(aidx);
        };
      })());
    }

    accord_td.appendChild(accord_btn);
    accord_td.appendChild(accord_hyper);

    if (dw.numRowsAtAccordion(accordIdx) > 0) {
      var data_tbody = document.createElement("tbody");
      table.appendChild(data_tbody);

      // put a click callback on the accordion cell to toggle row visibility
      accord_btn.addEventListener("click", (function () {
        var dtb = data_tbody;
        var a = accordIdx;
        return function (event) {
          toggleDisplay(dw, a, dtb, this);
        };
      })());

      for (var rowIdx = 0; rowIdx < dw.numRowsAtAccordion(accordIdx); rowIdx++) {

        // create the row data
        var data_tr = document.createElement("tr");
        data_tbody.appendChild(data_tr);

        for (var colIdx = 0; colIdx < dw.numCols(); colIdx++) {
          var idxstr = accordIdx.toString() + "_" + rowIdx.toString() + "_" + colIdx.toString();

          // build the col data
          var cell = data_tr.insertCell(colIdx);
          cell.id = "cell_" + idxstr;
          // align the cell
          cell.align = colAlign[colIdx];

          // set the color
          setElementBackgroundColor(cell, dw.getBGColorSemanticVarAt(accordIdx, rowIdx, colIdx));

          // add a click event listener on the cell
          cell.addEventListener("click", (function () {
            var a = accordIdx;
            var r = rowIdx;
            var c = colIdx;
            return function (event) {
              dw.setCellClickedAt(a, r, c);
            };
          })());

          // get the data for the cell
          var val_ = dw.getValueAt(accordIdx, rowIdx, colIdx);
          var edit_ = dw.getEditableAt(accordIdx, rowIdx, colIdx);
          var enabled_ = dw.getEnabledAt(accordIdx, rowIdx, colIdx);

          // control cell rendering
          var renderType = renderTypes[colIdx];
          var input = document.createElement("input");
          input.id = "input_" + idxstr;
          input.disabled = !enabled_;
          cell.appendChild(input);

          if (renderType === "bool") {
            // bool gets a checkbox
            input.type = "checkbox";
            input.checked = val_;

            // attach a callback to the checkbox. see https://www.pluralsight.com/guides/javascript-callbacks-variable-scope-problem
            // for more info on the cb structure, due to async nature of js callbacks
            input.addEventListener("change", (function () {
              var aidx = accordIdx;
              var rIdx = rowIdx;
              var cIdx = colIdx;
              return function (event) {
                checkCellChangedCB(dw, event, aidx, rIdx, cIdx);
              };
            })());

          } else if (renderType === "numeric") {
            // numeric text field

            input.type = "number";
            input.value = handleNumeric(val_);
            input.className = "numeric";
            input.style.textAlign = colAlign[colIdx];
            input.readOnly = !edit_;
            input.title = input.value;

            // attach a callback to the edit field. see https://www.pluralsight.com/guides/javascript-callbacks-variable-scope-problem
            // for more info on the cb structure, due to async nature of js callbacks
            input.addEventListener("change", (function () {
              var aidx = accordIdx;
              var rIdx = rowIdx;
              var cIdx = colIdx;
              return function (event) {
                numericCellChangedCB(dw, event, aidx, rIdx, cIdx);
              };
            })());


          } else {
            // string text field

            input.type = "text";
            input.value = val_.toString();
            input.className = "text";
            input.style.textAlign = colAlign[colIdx];
            input.readOnly = !edit_;
            input.title = input.value;

            // attach a callback to the edit field. see https://www.pluralsight.com/guides/javascript-callbacks-variable-scope-problem
            // for more info on the cb structure, due to async nature of js callbacks
            input.addEventListener("change", (function () {
              var aidx = accordIdx;
              var rIdx = rowIdx;
              var cIdx = colIdx;
              return function (event) {
                textCellChangedCB(dw, event, aidx, rIdx, cIdx);
              };
            })());
          }
        }
      }
    }
  }
}

function build(table, dw) {

  var nocontent = document.getElementById("nocontent");
  if (dw.numAccordions() > 0) { // dw.numAccordions() > 0
    nocontent.style.display = "none";

    // build the header
    buildHeader(table, dw);

    // build the accordions
    buildAccordions(table, dw);

    // create resize cols
    // createResizeCols(table);

    // update all header checkboxes
    updateAllHeaderCheckboxStates(dw);
  } else {
    nocontent.style.display = "block";
    nocontent.innerHTML = dw.getNoContentMsg();
  }

  // tell the world the html content is built
  dw.setHTMLIsBuilt()
}



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////UPDATE UI///////////////////////////////////

function update(table, dw) {
  if (dw.numAccordions() > 0) {
    // update the accordions
    updateAccordions(table, dw);

    // make sure headers are kept consistent
    updateAllHeaderCheckboxStates(dw);

    // simulate any qechanges
    qeSimulateEvent(table, dw);
  }
}

function updateAccordions(table, dw) {
  /*
  Update the accordions based on changes to the data. Note this assumes that
  the size/renderType/colAlign of the data never changes, only the content
  */
  var renderTypes = dw.getRenderTypes();
  for (var accordIdx = 0; accordIdx < dw.numAccordions(); accordIdx++) {

    // update accordion labels
    var accord_a = document.getElementById("accordhyper_" + accordIdx.toString());
    accord_a.innerHTML = dw.getAccordionTitle(accordIdx);

    for (var rowIdx = 0; rowIdx < dw.numRowsAtAccordion(accordIdx); rowIdx++) {
      for (var colIdx = 0; colIdx < dw.numCols(); colIdx++) {

        // get the renderType input element and value of the new data
        var renderType = renderTypes[colIdx];
        var input = getInputByIndex(accordIdx, rowIdx, colIdx);
        var cell = getCellByIndex(accordIdx, rowIdx, colIdx);
        var val = dw.getValueAt(accordIdx, rowIdx, colIdx);

        // get the edit/enable of the cell
        var edit = dw.getEditableAt(accordIdx, rowIdx, colIdx);
        var enabled = dw.getEnabledAt(accordIdx, rowIdx, colIdx);

        // update the cell background
        setElementBackgroundColor(cell, dw.getBGColorSemanticVarAt(accordIdx, rowIdx, colIdx));

        // update the input element
        input.disabled = !enabled;
        if (renderType === "bool") {
          input.checked = val;
        } else if (renderType === "numeric") {
          input.value = handleNumeric(val);
          input.readOnly = !edit;
          input.title = input.value;
        } else {
          input.value = val.toString();
          input.readOnly = !edit;
          input.title = input.value;
        }
      }
    }

    // check if the accordion needs to be expanded/collapsed, visible etc.
    updateAccordionVisibility(dw, accordIdx);
  }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////DEBUG///////////////////////////////////////

function buildTestTable() {


  // call jsonencode on some matlab TableAccordionData and copy to the datastr variable

  var datastr = '{"HeaderNames":["Name","Has Critic","Max Reward","Success?","Notes"],"RenderTypes":["text","bool","numeric","text","text"],"ColAlign":["left","center","center","center","center"],"ColWidth":["auto","auto","auto","auto","auto"],"AccordionData":[{"Name":"on_policy","AccordionTitle":"On-Policy","Editable":[[false,true,true,true,true],[false,true,true,true,true],[false,true,true,true,true],[false,true,true,true,true]],"Enabled":[[true,true,true,false,true],[true,true,true,false,true],[true,true,true,false,true],[true,true,true,false,true]],"BackgroundColor":[[[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1]],[[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1]],[[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1]],[[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1]]],"BackgroundColorSemanticVariable":[["","","","",""],["","","","",""],["","","","",""],["","","","",""]],"RenderTitleAsHyperlink":true,"IsAccordionVisible":true,"IsAccordionCollapsed":false,"RowData":[["PG",false,0,"no",""],["PG-Baseline",true,0,"no",""],["AC",false,0,"no",""],["PPO",true,0,"no",""]],"RowDataSize":[4,5]},{"Name":"off_policy","AccordionTitle":"Off-Policy","Editable":[[false,true,true,true,true],[false,true,true,true,true],[false,true,true,true,true]],"Enabled":[[true,true,true,false,true],[true,true,true,false,true],[true,true,true,false,true]],"BackgroundColor":[[[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1]],[[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1]],[[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1],[255,255,255,1]]],"BackgroundColorSemanticVariable":[["","","","",""],["","","","",""],["","","","",""]],"RenderTitleAsHyperlink":true,"IsAccordionVisible":true,"IsAccordionCollapsed":true,"RowData":[["DQN",true,0,"no",""],["DDPG",true,0,"no",""],["TD3",true,0,"no",""]],"RowDataSize":[3,5]}],"NoContentMsg":"NO CONTENT","NumCols":5,"NumAccordions":2,"JSEventData":{},"QEHTMLData":[],"HTMLIsBuilt":false}'

  var tableData = JSON.parse(datastr);
  var hc = { Data: tableData };
  var dw = new DataWrapper(hc);
  console.log(dw);

  // build the accordiontable
  var table = document.getElementById("accordtable");
  build(table, dw);

  // DEBUG
  global_dw = dw;

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////QE//////////////////////////////////////////

function qeSimulateEvent(table, dw) {
  var qedata = dw.getQEHTMLData();
  if (qedata) {
    switch (qedata.Type) {

      case "change":

        var elid = qedata.Data.ElementID;
        var val = qedata.Data.Value;
        var el = document.getElementById(elid);
        var tag = el.tagName;

        switch (tag) {
          case "INPUT":
            if (el.type === "checkbox") {
              el.checked = val;
            } else {
              el.value = val.toString();
            }
            el.dispatchEvent(new Event("change"));
            break;
          default:
            el.innerHTML = val.toString();
            el.dispatchEvent(new Event("change"));
            break;
        }

      case "click":

        var elid = qedata.Data.ElementID;
        var el = document.getElementById(elid);

        el.dispatchEvent(new Event("click"));
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////MATLAB INTERFACE////////////////////////////

function setup(htmlComponent) {

  var dw = new DataWrapper(htmlComponent);

  // get the parent table
  var table = document.getElementById("accordtable");

  // build the accordiontable
  build(table, dw);

  // add a listener every time the MATLAB data is changed
  htmlComponent.addEventListener("DataChanged",
    function (event) {

      // update the UI
      update(table, dw);
    }
  );
}

////////////////////////////////////////////////////////////////////////////////
//////////////////ON START (only when launching in web browser)/////////////////

// if (typeof htmlComponent == 'undefined') {
//   document.addEventListener("DOMContentLoaded", function(event) {
//     buildTestTable();
//   });
// }
