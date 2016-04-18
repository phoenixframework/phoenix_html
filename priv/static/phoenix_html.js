'use strict';

window.addEventListener('click', function (event) {
  if(event.target && event.target.matches('a[data-submit=parent]')) {
    var message = event.target.getAttribute('data-confirm');
    if (message === null || confirm(message)) {
      event.target.parentNode.submit();
    };
    event.preventDefault();
    return false;
  }
}, false);