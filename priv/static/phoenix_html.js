"use strict";

window._PhxForms = window._PhxForms || Object.freeze({
  eventConstructor: function () {
    if (typeof window.CustomEvent === "function") return window.CustomEvent;
    // IE<=9 Support
    function CustomEvent(event, params) {
      params = params || {bubbles: false, cancelable: false, detail: undefined};
      var evt = document.createEvent('CustomEvent');
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
      return evt;
    }
    CustomEvent.prototype = window.Event.prototype;
    return CustomEvent;
  },
  buildHiddenInput: function (name, value) {
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  },
  handleClick: function (element) {
    var to = element.getAttribute("data-to"),
        method = window._PhxForms.buildHiddenInput("_method", element.getAttribute("data-method")),
        csrf = window._PhxForms.buildHiddenInput("_csrf_token", element.getAttribute("data-csrf")),
        form = document.createElement("form"),
        target = element.getAttribute("target");

    form.method = (element.getAttribute("data-method") === "get") ? "get" : "post";
    form.action = to;
    form.style.display = "hidden";

    if (target) form.target = target;

    form.appendChild(csrf);
    form.appendChild(method);
    document.body.appendChild(form);
    form.submit();
  },
  clickHandler: function (e) {
    var element = e.target;
    var PolyfillEvent = window._PhxForms.eventConstructor();
    var phoenixLinkEvent = new PolyfillEvent('phoenix.link.click', {
      "bubbles": true,
      "cancelable": true
    });

    while (element && element.getAttribute) {
      if (!element.dispatchEvent(phoenixLinkEvent)) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return false;
      }

      if (element.getAttribute("data-method")) {
        window._PhxForms.handleClick(element);
        e.preventDefault();
        return false;
      } else {
        element = element.parentNode;
      }
    }
  },
  confirmHandler: function (e) {
    var message = e.target.getAttribute("data-confirm");
    if (message && !window.confirm(message)) {
      e.preventDefault();
    }
  }
});

(function() {
  window.addEventListener("click", window._PhxForms.clickHandler, false);
  window.addEventListener('phoenix.link.click', window._PhxForms.confirmHandler, false);
})();
