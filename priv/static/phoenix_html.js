'use strict';

/**
* The underneath has been adapted from:
* https://github.com/phoenixframework/phoenix_html/blob/51b0866afb3907cda652b94e8be77bc6929608d7/priv/static/phoenix_html.js
*/
function isLinkToSubmitParent(element) {
  var isLinkTag = element.tagName === 'A';
  var shouldSubmitParent = element.getAttribute('data-submit') === 'parent';

  return isLinkTag && shouldSubmitParent;
}

function getClosestForm(element) {
  while (element && element !== document && element.nodeType === Node.ELEMENT_NODE) {
    if (element.tagName === 'FORM') {
      return element;
    }
    element = element.parentNode;
  }
  return null;
}

function didHandleSubmitLinkClick(element) {
  while (element && element.getAttribute) {
    if (isLinkToSubmitParent(element)) {
      var message = element.getAttribute('data-confirm');
      if (typeof(window.jQuery) != undefined && $('#phoenix-bs-modal').length) {
        willHandleConfirmLinkClick($('#phoenix-bs-modal'), message).then(function (e) {
          getClosestForm(element).submit();
        });
      } else if (message === null || confirm(message)) {
        getClosestForm(element).submit();
      }
      return true;
    } else {
      element = element.parentNode;
    }
  }
  return false;
}

window.addEventListener('click', function (event) {
  if (event.target && didHandleSubmitLinkClick(event.target)) {
    event.preventDefault();
    return false;
  }
}, false);

/**
* willHandleConfirmLinkClick (modal, message) takes a jQuery DOM element and
*   a message string (optional). modal is expected to conform loosely to the
*   Bootstrap modal component described at
*   https://getbootstrap.com/javascript/#modals
*
* willHandleConfirmLinkClick return a Promise object that resolves if and only
*   the user confirms his/her input by clicking the '.btn-primary' button in the
*   modal dialogue.
*/
function willHandleConfirmLinkClick(modal, message) {
  return new Promise((resolve, reject) => {
    modal.on('show.bs.modal', function(e) {
      if (message !== null) {
        modal.find('.modal-body p').text(message);
      }
      modal.find('.btn-primary').click(function(e) {
        modal.modal('hide');
        resolve();
      });
    });
    modal.on('hide.bs.modal', function(e) {
      modal.find('.btn-primary').off('click');
    });
    modal.modal('show');
  });
}
