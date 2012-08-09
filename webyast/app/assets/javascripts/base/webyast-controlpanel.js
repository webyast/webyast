/*
#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++
*/

var currentURL = window.location.toString().split("/");

//Match the control panel (index page) and enable tracking
if(currentURL.pop.length == 0) {
  $(function() {
    var $plugins = $('#webyast_plugins');
    var $data = $plugins.clone();
    var $sortedData = $data.find('li');
    var $filters = $('#filter').find('label.quicksand_button');

     $('#filter label').bind('click', function() {
       $filters.removeClass('quicksand_button_active');
       $(this).addClass('quicksand_button_active');
       
       if($(this).attr('value') == "All") {
          $sortedData = $data.find('li');
       } else {
          $sortedData = $data.find('li[data-type=' + $(this).attr('value') + ']');
       }
       quicksort($plugins, $sortedData)
     })
  });

  hideFilters = function() {
    $('#filter_all').removeClass('quicksand_button_active');
    $('#hidden_filters').fadeOut();
  }

  $(function() {
    $('#filter_all').click(function() {
      $('#hidden_filters').fadeIn();
      $('#filter_recent').hide();
      $(this).addClass('quicksand_button_active');
    })
  });

  initTipsyTooltip = function() {
    var $webyast_plugins = $('#webyast_plugins');
    console.log("tipsy")
    $webyast_plugins.find('li').unbind('mouseenter mouseleave');
    $webyast_plugins.find('a.plugin_link').tipsy({gravity: 'n', offset: 8, delayIn: 500, live:false, opacity: 0.7 });
    console.log( $webyast_plugins.find('a.plugin_link'))
  }

  var quicksort = function ($plugins, $data) {
   
   $plugins.find('a').unbind();
   
   $plugins.quicksand($data, {
      duration: 400,
      adjustHeight: 'dynamic',
      attribute: 'id',
      easing: 'easeInOutQuad'
      }, function() { 
        setTimeout(initTipsyTooltip, 100);
      }
    ); 
  }

  function sortCallbackFunc(a,b){
    if(a.value == b.value){
      if(a.value == b.value){
        return 0;
      }
      return (a.value > b.value) ? -1 : 1;
    }
    return (a.value > b.value) ? -1 : 1;
  }


  function sortAlphabetically(a,b){
    return $(a).find('strong').innerHTML > $(b).find('strong').innerHTML ? 1 : -1; 
  }

  //Reset usage statistic in 10 days
  function resetUsageStatistic() {
    var expiresIn = 864000;
    var today = getUnixTimestamp();
    var lastUsage = parseInt(localStorage.getItem('last_reset'));
    var expired = today - lastUsage;

    if(expired > expiresIn ) {
      return true;
    } else {
      return false;
    }
  }

  function resetModuleUsage(array) {
    for(i=0; i< array.length; i++) {
      var new_value = parseInt((array[i].value/2)+1);
      localStorage.setItem(array[i].name, new_value);
    }
    
    //update last_reset !!!
    localStorage.setItem('last_reset', getUnixTimestamp());
  }

  //Track frequenly used modules
  $(document).ready(function() {
  
    //localStorage.clear()
    if(localstorage_supported() && 'last_reset' in localStorage) {    
      // console.log("Sorted by usage")
      var $plugins = $('#webyast_plugins');
      var $list =  $plugins.find('li');
      var array = [];
      var $collection = [];
      
      //check date of first usage
      //divide nubmer of used modules every 10 days?
      if(resetUsageStatistic()) {
        $list.each(function(index, element) { 
          if($(element).attr('id') in localStorage) {
            array.push({name: $(element).attr('id'), value: localStorage.getItem($(element).attr('id'))})
            $collection.push(element)
          }
        });
        
        resetModuleUsage(array);
        
      } else {
        $list.each(function(index, element) { 
          if($(element).attr('id') in localStorage) {
            array.push({name: $(element).attr('id'), value: localStorage.getItem($(element).attr('id'))})
            $collection.push(element)
          }
        });
      }

      if(array.length > 5) {
        array = array.sort(sortCallbackFunc).splice(0, 5);
      } else {
        array = array.sort(sortCallbackFunc);
      }
      
      var $sorted = [];
      
      for(i=0; i< array.length; i++) {
        for(j=0; j< $collection.length; j++) {
          if($($collection[j]).attr('id') == array[i].name) {
            $sorted.push($collection[j]);
          }
        }
      }

      //INFO: Control panel index page - insert elements without quick sand animation
      //console.info("Localstorage is not empty")
      //$plugins.html($sorted);
      
      trackRecent();

    } else {
      // console.log("Sorted by name");
      var $plugins = $('#webyast_plugins');
      var $data = $plugins.clone();
      $data = $data.find('li.main');

      if($data.length > 5) { 
        $data = $data.sort(sortAlphabetically).splice(0, 5); 
      } else {
        $data = $data.sort(sortAlphabetically)
      }

      //INFO: Control panel index page - insert elements without quick sand animation
      //console.info("Localstorage empty")
      //$plugins.html($data);
      trackRecent();
    }
  })

  function trackRecent() {
    if(localstorage_supported()) {
     $('#webyast_plugins li').live('click', function(e) {
        if('last_reset' in localStorage != true) { lastReset(getUnixTimestamp()); }
        if($(this).attr('id') in localStorage) {
          var value = parseInt(localStorage.getItem($(this).attr('id'))) + 1;
          localStorage.setItem($(this).attr('id'), value);
        } else {
          localStorage.setItem($(this).attr('id'), 1);
        }
      });
    }
  }

  function lastReset(timestamp) {
    if(localstorage_supported()) {
      localStorage.setItem("last_reset", timestamp);
    }
  }

  function getUnixTimestamp() {
    timestamp = Math.round((new Date()).getTime() / 1000);
    return timestamp;
  }
} 
