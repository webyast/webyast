/*
#--
# Webyast Webservice framework
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

function badBrowser(){
    if(   ($.browser.msie() && $.browser.version.number() == 8 )
       || ($.browser.firefox() && $.browser.version.number() >= 3.5 )
      ) { return false;}
//chrome detection, not supported by our version of jqbrowser
    if ( /Chrome/.test(navigator.userAgent))
    {
      //chrome detected, check major version
      var version = /Chrome\/([0-9]+)/.exec(navigator.userAgent)[1];
      if (parseInt(version) >= 4)
        return false;
    }
    return true;
}

function getBadBrowser(c_name)
{
    if (document.cookie.length>0) {
	c_start=document.cookie.indexOf(c_name + "=");
	if (c_start!=-1) { 
            c_start=c_start + c_name.length+1; 
            c_end=document.cookie.indexOf(";",c_start);
            if (c_end==-1) c_end=document.cookie.length;
                return unescape(document.cookie.substring(c_start,c_end));
        } 
    }
    return "";
}	

function setBadBrowser(c_name,value,expiredays)
{
    var exdate=new Date();
    exdate.setDate(exdate.getDate()+expiredays);
    document.cookie=c_name+ "=" +escape(value) + ((expiredays==null) ? "" : ";expires="+exdate.toGMTString());
}

if(badBrowser() && getBadBrowser('browserWarning') != 'seen' ){
    $(function(){
      $("#browserWarning").show();
      $('#warningClose').click(function(){
        setBadBrowser('browserWarning','seen');
        $('#browserWarning').slideUp('slow');
        return false;
      });
    });
}
