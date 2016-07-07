'use strict';

function didHandleSubmitLinkClick(element){
  while(element) {
    if(element.matches && element.matches('a[data-submit=parent]')){
      var message = element.getAttribute('data-confirm');
      if (message === null || confirm(message)) {
        element.parentNode.submit();
      };
      return true;
    } else {
      element = element.parentNode;
    }
  }
  return false;
}

// for links with HTTP methods other than GET
window.addEventListener('click', function (event) {
  if(event.target && didHandleSubmitLinkClick(event.target)) {
    event.preventDefault();
    return false;
  }
}, false);
