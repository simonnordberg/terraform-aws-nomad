#!/bin/sh
set -e

/tmp/terraform-aws-nomad/modules/install-nomad/install-nomad --version "${NOMAD_VERSION}"
/tmp/terraform-aws-consul/modules/install-consul/install-consul --version "${CONSUL_VERSION}"
