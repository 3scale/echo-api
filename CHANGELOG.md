# Change Log

Notable changes to echo-api will be tracked in this document.

## 1.0.2 - 2020-12-15

### Added

- The README now has some minimal information about the container image, deployment
  on Openshift and Istio, and how to enable Jaeger support.

### Changed

- Tracing related gems won't be loaded if echo-api won't be using them.
- Updated Puma from version 4.3 to 5.1.
- Updated Ruby Jaeger client from 1.0 to 1.1.
- Updated Rack, Sinatra, Json, Nokogiri to fix bugs and close security issues.
- The container image now uses Ruby 2.7, Bundler 2.2.1 and the latest minimal Red Hat UBI (RHEL 8.3).
- Updated the CI to use Jaeger 1.21 and Ruby 2.7.
- Removed docs from installed packages in the container image since microdnf is now fixed.

## 1.0.1 - 2020-05-25

### Changed

- Updated Puma, Rack and Nokogiri to close security issues.
- Updated Rack to 2.2.2 to track newer development.
- The provided Openshift and Istio templates now point to the "stable" tag.
