/*
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
*/

// add Array map method, if we don't have any
if (!Array.prototype.map)
{
  Array.prototype.map = function(fun /*, thisp*/)
  {
    var len = this.length;
    if (typeof fun != "function")
      throw new TypeError();

    var res = new Array(len);
    var thisp = arguments[1];
    for (var i = 0; i < len; i++)
    {
      if (i in this)
        res[i] = fun.call(thisp, this[i], i, this);
    }
    return res;
  };
};

// add Array indexOf method, if we don't have any
if(!Array.prototype.indexOf){
  Array.prototype.indexOf = function(obj){
    for(var i=0; i<this.length; i++){
      if(this[i]==obj){
        return i;
      }
    };
    return -1;
  }
};


function update (obj1,obj2) {
  var new_obj = new Object();
  for (var i in obj1) { new_obj[i] = obj1[i] };
  for (var i in obj2) { new_obj[i] = obj2[i] };
  return new_obj;
};

function getContents(item) { return item.innerHTML; };

function select_many_dialog( kvargs ) {
  var include = function (arr,item) { 
    return arr.indexOf(item) == (-1) ? false : true; 
  }
   // load settings from parameters of default
  var default_settings = {
    kind           : "items",
    title          : "Select items",
    selected_title : "Selected items",
    unselected_title : "Available items",
    tooltip : "Click items to select / unselect"
  };
  // preferably use settings from arguments
  var settings = update(default_settings, kvargs );
  var kind = settings.kind;
  // create a basic dialog html
  var d;
  d  = '<div id="select-' + kind + '-dialog\" style="display:none;" title="'+settings.title+'">\n';
  d += '  <input type="hidden" id="select-' + kind + '-current-id" value=""/>\n';
  d += '  <div class="dialog-container">\n';
  d += '    <h2>'+settings.selected_title+'</h2>\n';
  d += '    <div id="selected-' + kind + '"/>\n';
  d += '  </div>\n';
  d += '  <div class="dialog-container">\n';
  d += '    <h2>'+settings.unselected_title+'</h2>\n';
  d += '    <div id="unselected-' + kind + '"/>\n';
  d += '  </div>\n';
  d += '  <div class="select-tooltip">'+settings.tooltip+'</div>\n';
  d += '</div>';
  $("body").append(d);
  
  // 'map' doesn't work on jQuery arrays for some reason. Don't know why.
  function getSelectedItems() {
    var selected_items = [];
    $("#selected-"+kind).children(":visible").each( function (i) {
      selected_items.push( getContents( this ) );
    });
    return selected_items;
  }
  // say that the html is a dialog
  $("#select-"+kind+"-dialog").dialog({
    autoOpen : false,
    width : 600,
    height: 400,
    modal : true,
    buttons : {
      'Ok': function() {
          settings.storeItems( $("#select-"+kind+"-current-id").attr('value'),
                               getSelectedItems() );
          $(this).dialog('close');
        }, 
      'Cancel': function() { $(this).dialog('close'); }
    }
  });
  var renderItemCond = function(item,cond) {
    display_str = cond(item) ? "" : ' style="display: none"';
    return ('<span class="select-dialog-item" value="'+item+'"' + display_str + '>'+item+'</span>');
  };
 
  function showIf(item, condition) {
    condition ? item.show() : item.hide();
  }

  function setSelected(item, is_being_selected) {
    showIf( $('#selected-'+kind  ).children("[value='"+item+"']") ,   is_being_selected );
    showIf( $('#unselected-'+kind).children("[value='"+item+"']") , ! is_being_selected );
  }

  // create function for opening the dialog
  var open_dialog = function (dialogId) {
    var selected_list = settings.loadItems(dialogId);
    var all_items     = settings.allItems();
    var itemSelected         = function (item) { return include(selected_list,item) };
    var itemUnselected       = function (item) { return ! include(selected_list,item) };
    var renderSelectedItem   = function (item) { return renderItemCond(item, itemSelected) };
    var renderUnselectedItem = function (item) { return renderItemCond(item, itemUnselected) };
    // empty 'selected' and 'unselected' container
    $('#selected-'+kind+',#unselected-'+kind).empty();
    // same dialog can be used for several different selections, we have to save dialog/selection id
    $('#select-'+kind+'-current-id').attr('value',dialogId);
    // fillup new values for selected and unselected items
    $('#selected-'+kind).append(  all_items.map( renderSelectedItem   ).join("\n") );
    $('#unselected-'+kind).append(all_items.map( renderUnselectedItem ).join("\n") );
    // make items selectable/unselectable on click
    $('#unselected-'+kind).children().click( function () { setSelected( this.getAttribute('value'), true ) } );
    $('#selected-'+kind  ).children().click( function () { setSelected( this.getAttribute('value'), false) } );
    // call the dialog
    $('#select-'+kind+'-dialog').dialog('open');
  };
  return open_dialog;
};

function select_one_dialog( kvargs ) {
   // load settings from parameters of default
  var default_settings = {
    kind           : "items",
    title          : "Select item",
    tooltip : "Click item to select it."
  };
  // preferably use settings from arguments
  var settings = update(default_settings, kvargs );
  var kind = settings.kind;
  // create a basic dialog html
  var d;
  d  = '<div id="select-one-' + kind + '-dialog\" style="display:none;" title="'+settings.title+'">\n';
  d += '  <input type="hidden" id="select-' + kind + '-current-id" value=""/>\n';
  d += '  <div class="dialog-container">\n';
  d += '    <div id="available-' + kind + '"/>\n';
  d += '  </div>\n';
  d += '  <div class="select-tooltip">'+settings.tooltip+'</div>\n';
  d += '</div>';
  $("body").append(d);
  
  // say that the html is a dialog
  $("#select-one-"+kind+"-dialog").dialog({
    autoOpen : false,
    width : 600,
    height: 400,
    modal : true
  });

  var renderItem = function(item) {
    return ('<span class="select-dialog-item" value="'+item+'">'+item+'</span>');
  };

  var itemClick = function(dialogId,item) {
    settings.storeItem( dialogId, getContents( item ) );
    $("#select-one-"+kind+"-dialog").dialog('close');
  };
 
  // create function for opening the dialog
  var open_dialog = function (dialogId) {
    var all_items     = settings.allItems();
    $('#available-'+kind).empty();
    $('#available-'+kind).append( all_items.map( renderItem ).join("\n") );
    $('#available-'+kind).children().click( function () { itemClick( dialogId, this ) } );
    $('#select-one-'+kind+'-dialog').dialog('open');
  };
  return open_dialog;
};

