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

Features:
  * Add option to use success_action_status instead of success_action_redirect (Nick DeLuca @nddeluca)

Bug Fixes:
 * Remove intial slash when generating key from url in order to fix updates (Enrique García @kikito)
 * Fix key generation when #default_url is overriden (@dunghuynh)
 * Fix policy glitch that allows other files to be overwritten (@dunghuynh)

Misc:
 * Update resque url in readme (Ever Daniel Barreto @everdaniel)
 * update readme (Philip Arndt @parndt)


### 0.0.12

Features:
  * use uuidtools gem instead of uuid gem for uid generation (Filip Tepper @filiptepper)

Bug Fixes:
  * fix URI parsing issues with cetain filenames (Ricky Pai @rickypai)
  * prevent double slashes in urls generated from direct_fog_url (Colin Young @colinyoung)

Misc:
 * fix typo in readme (@hartator)

