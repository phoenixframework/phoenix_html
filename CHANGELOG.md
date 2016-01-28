# Changelog

## v2.5.0 (2016-01-28)

* Enhancements
  * Introduce `form.data` field instead of `form.model`. Currently those values are kept in sync then the form is built but `form.model` will be deprecated in the long term

## v2.4.0 (2016-01-21)

* Enhancements
  * Add `rel=nofollow` auto generation for non-get links
  * Introduce `:selected` option for `select`  and `multiple_select`

* Bug fixes
  * Fix safe engine incorrectly marking safe code as unsafe when last expression is `<% ... %>`

## v2.3.0 (2015-12-16)

* Enhancements
  * Add `escape_javascript/1`
  * Add helpful error message when using unknown `@inner` assign
  * Add `Phoenix.HTML.Format.text_to_html/2`

## v2.2.0 (2015-09-01)

* Bug fix
  * Allow the `:name` to be given in forms. For this, using `:name` to configure the underlying input name prefix has been deprecated in favor of `:as`

## v2.1.2 (2015-08-22)

* Bug fix
  * Do not include values in `password_input/3`

## v2.1.1 (2015-08-15)

* Enhancements
  * Allow nil in `raw/1`
  * Allow block options in `label/3`
  * Introduce `:skip_deleted` in `inputs_for/4`

## v2.1.0 (2015-08-06)

* Enhancements
  * Add an index field to forms to be used by `inputs_for/4` collections

## v2.0.1 (2015-07-31)

* Bug fix
  * Include web directory in Hex package

## v2.0.0 (2015-07-30)

* Enhancements
  * No longer generate onclick attributes.

    The main motivation for this is to provide support
    for Content Security Policy, which recommends
    disabling all inline scripts in a page.

    We took the opportunity to also add support for
    data-confirm in `link/2`.

## v1.4.0 (2015-07-26)

* Enhancements
  * Support `input_type/2` and `input_validations/2` as reflection mechanisms

## v1.3.0 (2015-07-23)

* Enhancements
  * Add `Phoenix.HTML.Form.inputs_for/4` support
  * Add multiple select support
  * Add reset input
  * Infer default text context for labels

## v1.2.1 (2015-06-02)

* Bug fix
  * Ensure nil parameters are not discarded when rendering input

## v1.2.0 (2015-05-30)

* Enhancements
  * Add `label/3` for generating a label tag within a form

## v1.1.0 (2015-05-20)

* Enhancements
  * Allow do/end syntax with `link/2`
  * Raise on missing assigns

## v1.0.1

* Bug fixes
  * Avoid variable clash in Phoenix.HTML engine buffers

## v1.0.0

* Enhancements
  * Provides an EEx engine with HTML safe rendering
  * Provides a `Phoenix.HTML.Safe` protocol
  * Provides a `Phoenix.HTML.FormData` protocol
  * Provides functions for generating tags, links and form builders in a safe way
