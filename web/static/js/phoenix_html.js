function isLinkToSubmitParent(element) {
  var isLinkTag = element.tagName === 'A';
  var shouldSubmitParent = element.getAttribute('data-submit') === 'parent';

  return isLinkTag && shouldSubmitParent;
}

function didHandleSubmitLinkClick(element) {
  while(element) {
    if(isLinkToSubmitParent(element)) {
      var message = element.getAttribute('data-confirm');
      if (message === null || confirm(message)) {
        element.parentElement.submit();
      };
      return true;
    } else {
      element = element.parentElement;
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
