# Change Log

Notable changes to echo-api will be tracked in this document.

## 1.0.4 - 2021-09-21

### Added

- ppc64le builds are now executed on Travis.

### Changed

- Updated gems for Nokogiri to 1.12.4 and Puma to 5.5.0.
- Updated transitive dependencies.
- Updated Bundler to 2.2.27.

### Removed

- The OpenAPI specification has been removed as it was unmaintained.

## 1.0.3 - 2021-01-08

### Added

- Sample manifests for deploying on Kubernetes with and without Jaeger have been added to the `contrib/kubernetes` directory.

### Fixed

- Updated Bundler to 2.2.4. This should fix issues running the app on OpenShift.

### Changed

- Updated gems for Nokogiri to 1.11.1 and json to 2.5.1.

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
