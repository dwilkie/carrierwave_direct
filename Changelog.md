### 0.0.14

[Full Changes](https://github.com/dwilkie/carrierwave_direct/compare/v0.0.13...master)

Features:
 * Add ability to set content type in upload form (John Kamenik @jkamenik)
 * Dutch language support (Ariejan de Vroom @ariejan)

Bug Fixes:
  * Escape characters in filenames (@geeky-sh)
  * Use OpenSSL::Digest instead of OpenSSL::Digest::Digest (@dwiedenbruch)
  * Fix signature race condition by caching policy (Louis Simoneau @lsimoneau)
  * Fix multi-encoding issue when saving escaped filenames (Vincent Franco @vinniefranco)
  * Use mounted-on column name for uniqueness validation (Stephan Schubert @jazen)

Misc:
  * Improve readme documentation for success action status support (Rafael Macedo @rafaelmacedo)
  * Increase robutness of view rpsec matchers (@sony-phoenix-dev)
  * Add ruby 2.1.0 support to travis (Luciano Sousa @lucianosousa)

### 0.0.13

### 0.0.12

