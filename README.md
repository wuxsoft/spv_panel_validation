# PanelValidation

WS Security XML Certificate signing for Ruby

## Installation

```bash
gem install spv_panel_validation
```

## Usage

```bash

export GREENDEAL_CERT_PATH=cert.pem
export GREENDEAL_PRIVATE_KEY_PATH=key.pem
export GREENDEAL_PRIVATE_KEY_PASSWORD=xxxxx
export REFERENCE_DATA_PATH=referenceData.json
Example:

export GREENDEAL_CERT_PATH=/Users/hogan/work/osw/ezyform/public/xml/cert.pem
export GREENDEAL_PRIVATE_KEY_PATH=/Users/hogan/work/osw/ezyform/public/xml/key.pem
export GREENDEAL_PRIVATE_KEY_PASSWORD=gd@cd
export REFERENCE_DATA_PATH=/Users/hogan/work/osw/ezyform/public/xml/referenceData.json

```

```ruby
require "spv_panel_validation/reference_data"
require "spv_panel_validation/xml_digital_signature"


```
